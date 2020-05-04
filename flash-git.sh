#!/bin/bash

declare -i FLASH_GIT_VERSION=0

source /usr/share/flash-git/flash-git__fs.sh # myMkfs, myMount
source /usr/share/flash-git/flash-git__hw.sh # detectHardwareForMedia

udevRulesPath=/etc/udev/rules.d/10-flash-git.rules

for i in $*
do
	if [[ "$i" == "--help" || $i == "-h" ]]
	then
		echo "
Synchronizer for local repositories (on some machines) through a flash-drive.
All options but "--help" require to be runned under root.

options:

--help
    show this help

--device=<xx>
    set flash-device xx. Sync device with local repositories if addon options is not set.

--user=<user>
    set user to set new local repository ownership

--group=<group>
    set group to set new local repository ownership

--show-registered
    list auto-processing devices (not fake but real)

USAGE:

  get help:
  $ flash-git --help
  no matter if in addon to "--help" would be any other arguments - they will be ignored

  initialize media by local repositories:
  # flash-git --device=<DEVICE> --alias=<ALIAS> --repo-list=<REPO_LIST>

  initialize local repositories by media:
  # flash-git --device=<DEVICE> --user=<USER> --group=<GROUP>

  initiate syncronization:
  # flash-git --device=<DEVICE>

  unchain media from local repositories:
  # flash-git --free
    flash-git will ask you for media to free

  restore media via local repositories
  # flash-git --restore=<DEVICE>
    previously flash-drive will be discarded

  show using devices and repositories:
  # flash-git --show-registered

Copyright © 2020 Boris Vasilev. License MIT: <https://github.com/1024sparrow/flash-git/blob/master/LICENSE>
"
		exit 0
	fi
done

if [ ! $(id -u) -eq 0 ]
then
    echo Run this under ROOT only!
    exit 1
fi

allArgs=(
    argFree
    argRestore
    argShowRegistered
    argUser
    argGroup
    argRepoList
    argDevice
    argAlias
)

validArgsCombinations=(
    "argFree"
    "argRestore argAlias"
    "argShowRegistered"
    "argDevice"
    "argDevice argRepoList argAlias"
    "argDevice argUser argGroup"
)

function checkArgUser {
    if [ "$(grep -c "^$1:" /etc/passwd)" -eq 0 ]
    then
        echo "there is not such user: $1"
        exit 1
    fi
}

function checkArgGroup {
    if [ "$(grep -c "^$1:" /etc/group)" -eq 0 ]
    then
        echo "there is not such group: $1"
        exit 1
    fi
}

function checkArgRepoList {
    echo checkArgRepoList
    if [ ! -r "$1" ]
    then
        echo "Repositories list \"$1\": file not found"
        exit 1
    fi
    while read -r line
    do
        tmp="$line"
        if [ ! -z "$argSandbox" ]
        then
            tmp=sandboxes/"$argSandbox"/"$line"
        fi
        if [ ! -d "$tmp" ]
        then
            echo "repository not found: $line"
            exit 1
        fi
        pushd "$tmp"
        git status &> /dev/null || (echo "directory \"$line\" not initialized as git-repository"; exit 1)
        popd
    done < "$1"
}

function checkMediaDevice {
    if [ ! -b "$1" ]
    then
        echo "\"$1\" is not valid media device"
        exit 1
    fi
}

function normalizeUdevRules {
    state=false
    # 0 - "# local ID:" not appeared, do not pass any "KERNEL=="
    # 1 - "# local ID:" appeared, do pass one "KERNEL=="
    echo -n > /etc/udev/rules.d/10-flash-git.rules
    tmpfile=$(mktemp)
    while read -r line
    do
        if [[ "${line:0:11}" == "# local ID:" ]]
        then
            state=true
            echo "$line" >> $tmpfile
        elif [[ "${line:0:8}" == "KERNEL==" ]]
        then
            if $state
            then
                echo "$line" >> $tmpfile
                cat $tmpfile >> /etc/udev/rules.d/10-flash-git.rules
                echo -n > $tmpfile
                state=false
            fi
        else
            echo "$line" >> /etc/udev/rules.d/10-flash-git.rules
        fi
    done < $1
    rm $tmpfile
}

function freeMedia {
    # if argument set: only delete from udev.rules
    # request localID for device and totally delete that
    if [ $1 ]
    then
        internalId=$1
    else
        showRegistered
        echo -n "
Select internal ID: "
        read internalId
    fi
    pushd /usr/share/flash-git
    if [ ! -d $internalId ]
    then
        echo "incorrect selection"
        exit 1
    fi
    pushd $internalId
    tmpAlias=$(cat alias)

    tmp=$(mktemp)
    while read -r line
    do
        if [[ "$line" != "# local ID: $internalId" ]]
        then
            echo "$line" >> $tmp
        fi
    done < /etc/udev/rules.d/10-flash-git.rules
    normalizeUdevRules $tmp
    udevadm control --reload-rules && udevadm trigger
    rm $tmp
    popd # internalId
    if [ -z "$1" ]
    then
        rm -rf $internalId
    fi
    popd # /usr/share/flash-git

}

function addMediaToUdev {
    # Arguments:
    #   1. Hardware file
    #   2. Internal ID
    source $1
    cand="KERNEL==\"sd[b-z]*\", ATTRS{idVendor}==\"${ID_idVendor}\", ATTRS{idProduct}==\"${ID_idProduct}\", ATTRS{serial}==\"${ID_serial}\", ATTRS{product}==\"${ID_product}\", ATTRS{manufacturer}==\"${ID_manufacturer}\", RUN+=\"/usr/share/flash-git/flash-git__add.sh /dev/%k%n\""
    candIdMark="# local ID: $2"

    tmpUdev=$(mktemp)
    existen=false
    while read -r line
    do
        if [[ "$line" == "$cand" ]]
        then
            existen=true
            echo "$candIdMark" >> $tmpUdev
            echo "$line" >> $tmpUdev
            break
        fi
        echo "$line" >> $tmpUdev
    done < $udevRulesPath

    if $existen
    then
        cat $tmpUdev > $udevRulesPath
    else
        echo "$candIdMark" >> $udevRulesPath
        echo "$cand" >> $udevRulesPath
        udevadm control --reload-rules && udevadm trigger
    fi
    rm $tmpUdev
}

function checkRepolistAvailable {
    # Arguments:
    #   1. file with repolist
    # exit 1, if any already exists (in /usr/share/flash-git)
    while read -r line
    do
        for i in $(seq 100)
        do
            if [ -d /usr/share/flash-git/$i ]
            then
                while read -r lineStored
                do
                    if [[ "$line" == "$lineStored" ]]
                    then
                        return 1
                    fi
                done < /usr/share/flash-git/$i/repos
            fi
        done
    done < $1
    return 0
}

function burnFlash {
    # Arguments:
    #   1. device
    #   2. localId
    umount $1
    tmpAlias=$(cat alias)
    myMkfs $1 /usr/share/flash-git/$2 "fg_$tmpAlias"
    return $retval
}

function restoreMedia {
    # arguments:
    #   1. Device

    showRegistered
    echo -n "
Select internal ID: "
    read internalId
    pushd /usr/share/flash-git
    if [ ! -d $internalId ]
    then
        echo "incorrect selection"
        exit 1
    fi
    detectHardwareForMedia $1 /usr/share/flash-git/$internalId/hardware
    if ! burnFlash $1 $internalId
    then
        echo "FAILED"
        exit 1
    fi
    popd

    freeMedia $internalId

    tmp=$(mktemp)
    detectHardwareForMedia $1 $tmp
    addMediaToUdev $tmp $internalId
    rm $tmp
}

function showRegistered {
    if [ -d /usr/share/flash-git ]
    then
        pushd /usr/share/flash-git > /dev/null
        for i in $(seq 100)
        do
            if [ -d $i ]
            then
                echo "---- id: $i ----"
                tmp=$(cat $i/alias)
                echo "alias: \"$tmp\""
                echo "repositories:"
                while read -r line
                do
                    echo "  $line"
                done < $i/repos
            fi
        done
        popd > /dev/null
    fi
}

for i in $*
do
    #echo $i
    if [[ $i == "--free" ]]
    then
        argFree=true
    elif [[ ${i:0:10} == "--restore=" ]]
    then
        argRestore="${i:10}"
        checkMediaDevice "$argRestore"
    elif [[ $i == "--show-registered" ]]
    then
        argShowRegistered=true
    elif [[ ${i:0:7} == "--user=" ]]
    then
        argUser="${i:7}"
        checkArgUser "$argUser"
    elif [[ ${i:0:8} == "--group=" ]]
    then
        argGroup="${i:8}"
        checkArgGroup "$argGroup"
    elif [[ ${i:0:12} == "--repo-list=" ]]
    then
        argRepoList="${i:12}"
        if [ ! -r "$argRepoList" ]
        then
            echo "file \"$argRepoList\" not found"
            exit 1
        fi
        argRepoList=$(realpath "$argRepoList")
    elif [[ ${i:0:9} == "--device=" ]]
    then
        argDevice="${i:9}"
        checkMediaDevice "$argDevice"
    elif [[ ${i:0:8} == "--alias=" ]]
    then
        argAlias=${i:8}
    else
        echo "unexpected argument: $i
See \"--help\" for details."
        exit 1
    fi
done

function checkArguments {
    declare -i iComb=0
    declare -i counter=0
    declare -i allcounter=0
    while [ $iComb -lt ${#validArgsCombinations[@]} ]
    do
        allcounter=0
        counter=0
        br=false
        for i in ${allArgs[@]}
        do
            if [ ! -z ${!i} ]
            then
                exists=false
                for ii in ${validArgsCombinations[$iComb]}
                do
                    if [[ $i == $ii ]]
                    then
                        exists=true
                    fi
                done
                if [[ $exists == false ]]
                then
                    br=true
                fi
            fi
        done
        if [[ $br == true ]]
        then
            iComb+=1
            continue
        fi
        for i in ${validArgsCombinations[$iComb]}
        do
            allcounter+=1
        done
        for i in ${allArgs[@]}
        do
            for ii in ${validArgsCombinations[$iComb]}
            do
                if [[ $i == $ii ]]
                then
                    if [ ! -z ${!i} ]
                    then
                        counter+=1
                    fi
                fi
            done
        done
        if [ $allcounter -eq $counter ]
        then
            return
        fi
        iComb+=1
    done

    echo "incorrect arguments combination. See \"--help\" for details."
    exit 1
}

checkArguments

if [ $argFree ]
then
    echo "free media"
    freeMedia
    exit 0
elif [ $argRestore ]
then
    echo "restore media"
    restoreMedia $argRestore $argAlias
    exit 0
elif [ $argShowRegistered ]
then
    echo "show registered"
    showRegistered
    exit 0
elif [ $argDevice ] && [ $argRepoList ]
then
    echo "initialize local repositories by media"
    checkArgRepoList "$argRepoList"
elif [ $argDevice ] && [ $argUser ] && [ $argGroup ]
then
    echo "initialize media by local repositories"
elif [ $argDevice ] && [ -z "$argAlias" ]
then
	echo "sync"
	/usr/share/flash-git/flash-git__add.sh $argDevice && exit 0 || exit 1
fi

#echo "NOT IMPLEMENTED"
#exit 0

#function copy_flashgit_into_dir {
    #
#}

hostid=$(hostid)
if [[ ! -z "$argSandbox" ]]
then
    tmp=sandboxes/"$argSandbox"/hostid
    hostid=$(cat "$tmp")
fi

if [[ ! -d /usr/share/flash-git ]]
then
    mkdir /usr/share/flash-git
fi

tmpHardware=$(mktemp)
if [[ -z $argDevice ]]
then
    if [[ -z "$argRepoList" ]]
    then
        argAlias=$(cat fakeDevices/$argFakeDevice/alias)
    fi
    cat fakeDevices/$argFakeDevices/hardware > $tmpHardware
else
    if [[ -z "$argRepoList" ]]
    then
        prelmount=$(mktemp -d)
        myMount $argDevice $prelmount
        if [[ ! -r $prelmount/alias ]]
        then
            echo "incorrect media..."
            exit 1
        fi
        argAlias=$(cat $prelmount/alias)
        umount $prelmount
        rm -rf $prelmount
    fi
    detectHardwareForMedia $argDevice $tmpHardware
fi
pushd /usr/share/flash-git
for i in $(seq 100)
do
    if [[ -d $i ]]
    then
        if [[ $argAlias == $(cat $i/alias) ]] && cmp -s $tmpHardware $i/hardware
        then
            echo "this media already registered with such alias. Please unregiser registered previously or try another alias"
            exit 1
        fi
    fi
done

if [ "$argRepoList" ]
then
    if ! checkRepolistAvailable $(realpath "$argRepoList")
    then
        echo "you already have registered media for at least one repository"
        exit 1
    fi
else
    tmp=$(mktemp)
    myMount $argDevice $tmp && if ! checkRepolistAvailable $tmp/repos
    then
        umount $tmp
        echo "this media trails at least one repository you already have"
        exit 1
    fi
    umount $tmp
    rm -rf $tmp
fi

workdir=
localId=-1
for i in $(seq 100)
do
    if [[ ! -d $i ]]
    then
        mkdir $i
        echo $argAlias > $i/alias
        echo 0 > $i/flags
        cp $tmpHardware $i/hardware
        workdir=/usr/share/flash-git/$i
        localId=$i
        break
    fi
done
popd
if [[ -z $workdir ]]
then
    echo "Too many devices already registered. Rejected."
    exit 1
fi

if [ "$argRepoList" ]
then
	#source $hardwareFile
	#echo $ID_SERIAL

	rm -rf $workdir/root
	mkdir $workdir/root
    echo -n > $workdir/repos
    while read -r line
	do
        tmp="$line" # temporary stub. See lines below.
        #tmp=$(realpath "$line") # get absolute path # boris e: resolve for $argUser
        #if [[ $tmp == "$HOME/"* ]] # replace HomeDir for "~" # boris e: get $HOME for $argUser, not for root
        #then
        #    t=${#HOME}
        #    tmp=~/${tmp:$t}
        #fi
		repopath=$workdir/root/$(basename $tmp).git # boris e: add check for repositories names are all unique
        mkdir $repopath
		git init --bare --shared=true "$repopath"
		pushd "$tmp"
		git remote remove flash-git
		git remote add flash-git "$repopath"
		for branch in $(git branch | cut -c 3-)
		do
			git push --set-upstream flash-git "$branch"
		done
		git push flash-git
		popd # "$tmp"
	done < "$argRepoList"
	cp -L "$argRepoList" $workdir/repos # dereferencing if it's a symbolyc link
	#echo $hostid > $workdir/root/hosts

    #copy_flashgit_into_dir root
    echo $FLASH_GIT_VERSION > $workdir/flash_git_version

	burnFlash $argDevice $localId
	rm -rf $workdir/root

else
    tempdir=$(mktemp -d)
	myMount $argDevice $tempdir
	cp -rf $tempdir/* $workdir/ # boris e
	if [ $(cat $tempdir/flash_git_version) -gt $FLASH_GIT_VERSION ]
	then
		echo "you need to update flash-git to work with this device"
		exit 1
	fi
	umount $tempdir
	rm -rf $tempdir

	#if grep -Fxq $hostid root/hosts # if $hostid existen in root/hosts
	#then
	#	echo "reinitializing? Rejected."
	#	#exit 1
	#fi

	while read -r line
	do
        tmp="$line"
		if [ -d "$tmp" ]
		then
            rm -rf $workdir
			echo "Path '$line' already existen. FAILED."
			exit 1
		fi
	done < $workdir/repos

	while read -r line
	do
		echo "
${line}":
        tmp="$line"
        su ${argUser} -c "mkdir -p \"$tmp\""
		repopath=$workdir/root/"$(basename $line).git"
		git clone "$repopath" "$tmp"
		pushd "$tmp"
		git remote rename origin flash-git
		popd
		chown -R $argUser "$tmp"
		chgrp -R $argGroup "$tmp"
	done < $workdir/repos
	#echo $hostid >> root/hosts

	rm -rf $workdir/root
fi

if [ ! -f $udevRulesPath ]
then
    echo "# Edit this file ONLY via "flash-git" utility. Do not edit this manually!
" > $udevRulesPath
fi

if [ $argDevice ]
then
    addMediaToUdev $tmpHardware $localId
fi
