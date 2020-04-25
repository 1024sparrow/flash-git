#!/bin/bash

declare -i FLASH_GIT_VERSION=0

#underline=`tput smul`
#nounderline=`tput rmul`
#bold=`tput bold`
#normal=`tput sgr0`

udevRulesPath=/etc/udev/rules.d/10-flash-git.rules

for i in $*
do
	if [[ "$i" == "--help" || $i == "-h" ]]
	then
		echo "
Утилита для настройки автоматической синхронизации локальных git-репозиториев (на разных компьютерах) через флешку.

USAGE:

  get help:
  $ flash-git --help
  no matter if in addon to "--help" would be any other arguments - they will be ignored

  initialize media by local repositories:
  $ flash-git --device=<DEVICE> --alias=<ALIAS> --repo-list=<REPO_LIST>
  $ flash-git --fake-device=<FAKE_DEVICE> --repo-list=<REPO_LIST> --alias=<ALIAS> --sandbox=<SANDBOX>

  initialize local repositories by media:
  $ flash-git --device=<DEVICE> --user=<USER> --group=<GROUP>
  $ flash-git --fake-device=<FAKE_DEVICE> --user=<USER> --group=<GROUP> --sandbox=<SANDBOX>

  unchain media from local repositories:
  $ flash-git --free
    flash-git will ask you for media to free

  restore media via local repositories
  $ flash-git --restore=<DEVICE>
  previously flash-drive will be discarded
  $ flash-git --restore=<FAKE_DEVICE> # boris e
  # boris here e: udev-replaceable (for Windows and MacOS compatibility)

  # boris here 1: version checking for medias from the future
  # boris here 2: flash-git__add.sh

  show using devices and repositories:
  $ flash-git --show-registered

  create fake device:
  $ flash-git --create-fake-device=<FAKE_DEVICE>
  $ flash-git --show-fake-device=<FAKE_DEVICE>
  $ flash-git --create-sandbox=<SANDBOX> --user=<USER>
  $ flash-git --show-sandbox=<SANDBOX>
  $ flash-git --list-fake-devices
  $ flash-git --list-sandboxes
  $ flash-git --remove-fake-device=<FAKE_DEVICE>
  $ flash-git --remove-sandbox=<SANDBOX>



${underline}Инициализация флешки по локальным репозиториям:${nounderline}

* У локальных репозиториев прописывается флешка как дополнительный удалённый репозиторий, куда/откуда могут делаться делается push/pull (если эти репозитории были откуда-то стянуты, их origin остаётся на месте - все pull-push будут успешно проходить по-умолчанию туда, куда раньше проходили)
* В системе прописывается udev-правило на подключение КОНКРЕТНО ЭТОЙ флешки, что при её физическом подключении происходит
   * её автоматическое монтирование;
   * для всех указанных при инициализации репозиториев выполняется git pull;git push на флешку (см. более подробное описание этой процедуры ниже);
   * размонтирование флешки.
* На флешку записываются
   * список путей до локальных репозиториев, подлежащих синхронизации через эту флешку
   * Расшаренные клоны локальных репозиториев, на которые теперь можно делать pull/push
   * Уникальный идентификатор хоста - это для идентификации системой попытки повторно проинициализировать флешку

Порядок инициализации:
* составьте файл со списком путей до локальных репозиториев. Обозначим путь до этого файла как <путь_A>
* вставьте флешку (не монтируйте), определите файл её устройства (что-то вроде /dev/sdb)
* запустите от имени суперпользователя данный скрипт со следующими аргументами:

\$sudo ./flash-git.git --device=<ПУТЬ_ДО_УСТРОЙСТВА_ФЛЕШКИ> --repo-list=<путь_А>

${underline}Инициализация локальных репозиториев по флешке:${nounderline}

* По списку путей, записанных на флешку при инициализации флешки, клонируются с флешки репозитории (если по какому-то из этих путей директория уже есть на вашем компьютере, программа инициализации завершится, оповестив вас о невозможности инициализации репозиториев на вашем компьютере)
* В системе прописывается udev-правило на подключение КОНКРЕТНО ЭТОЙ флешки, что при её физическом подключении происходит
   * её автоматическое монтирование;
   * для всех указанных при инициализации репозиториев выполняется git pull;git push на флешку (см. более подробное описание этой процедуры ниже);
   * размонтирование флешки.
* На флешку записывается уникальный идентификатор хоста - это для идентификации системой попытки повторно проинициализировать репозитории по флешке

При клонировании репозиториев с флешки, при создании директорий для клонирования
все пути /home/*/... заменяются на /home/<ИМЯ_ПОЛЬЗОВАТЕЛЯ>/...

Порядок инициализации:
* вставьте флешку (не монтируйте), определите файл её устройства (что-то вроде /dev/sdb)
* запустите от имени суперпользователя данный скрипт со следующими аргументами:

\$sudo ./flash-git.git --device=<ПУТЬ_ДО_УСТРОЙСТВА_ФЛЕШКИ> --user=\$USER --group=\$USER

${underline}Дополнительные аргументы для отладки${nounderline}

Для тестирования и отладки данного скрипта поддерживается возможность работы не с реальной файловой системой и реальными флешками, а с песочницами и снимками флешек.
Песочница - это директория, в которой находится файл "hostid" с фейковым идентификатором хоста.
Снимок флешки - это директория, в которой находится файл с информацией о флешке (производитель, серийный номер и всё такое)

Данным скриптом поддерживаются следующие аргументы для отладки и тестирования:

--help
    show this help

--device=<xx>
    set flash-device xx

--fake-device=<xx>
    set fake-device xx

--user=<user>
    set user to set new local repository ownership

--group=<group>
    set group to set new local repository ownership

--sandbox=<ПЕСОЧНИЦА>
	В указанной выше директории должен находиться файл ${bold}hostid${normal} с фейковым идентификатором хоста

--show-registered
    list auto-processing devices (not fake but real)

--fake-insert=<СНИМОК_ФЛЕШКИ>
	Проиграть имитацию того, что была вставлена флешка

--fake-release=<СНИМОК_ФЛЕШКИ>
	Проиграть имитацию того, что флешка была извлечена (аппаратно)

--create-fake-device=<FAKE_DEVICE>
    create and initialize directory that can be in future pointed as fake device

--show-fake-device=<FAKE_DEVICE>
    show info about pointed fake device

--create-sandbox=<SANDBOX>
    create and initialize directory that can be in future pointed as a sandbox

--show-sandbox=<SANDBOX>
    show info about pointed sandbox

--list-fake-devices
    list all fake-devices names

--list-sandboxes
    list all sandboxes names

--remove-fake-device=<FAKE_DEVICE>
    remove fake device

--remove-sandbox=<SANDBOX>
    remove sandbox
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
    argSandbox
    argFakeinsert
    argFakeRelease
    argUser
    argGroup
    argRepoList
    argDevice
    argFakeDevice
    argAlias
    argCreateFakeDevice
    argShowFakeDevice
    argCreateSandbox
    argShowSandbox
    argListFakeDevices
    argListSandboxes
    argRemoveFakeDevice
    argRemoveSandbox
)

validArgsCombinations=(
    "argFree"
    "argRestore argAlias"
    "argShowRegistered"
    "argFakeinsert argSandbox"
    "argFakeRelease argSandbox"
    "argCreateFakeDevice"
    "argShowFakeDevice"
    "argListFakeDevices"
    "argRemoveFakeDevice"
    "argCreateSandbox argUser"
    "argShowSandbox"
    "argListSandboxes"
    "argRemoveSandbox"
    "argDevice argRepoList argAlias"
    "argFakeDevice argRepoList argSandbox argAlias"
    "argDevice argUser argGroup"
    "argFakeDevice argUser argGroup argSandbox"
)

function checkArgSandbox {
    if [ ! -d sandboxes/"$1" ]
    then
        echo "Not such directory: $1"
        exit 1
    fi
    if [ ! -r sandboxes/"$1"/hostid ]
    then
        echo "Directory \"$1\" does not present a sandbox"
        exit 1
    fi
}

function checkFakeMedia {
    echo checkArgFakeInsert
    if [ ! -r fakeDevices/"$1"/hardware ]
    then
        echo "\"$1\" is not a fake media"
        exit 1
    fi
}

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

function detectHardwareForMedia {
    # arguments:
    #   1. device
    #   2. file path to write hardware info
    for i in idVendor idProduct serial product manufacturer
    do
        var=$(udevadm info -a -n $1 | grep -m1 "ATTRS{$i}" | sed "s/^.*==\"//" | sed "s/\"$//")
        echo "ID_$i=\"$var\"" >> $2
    done
}

function normalizeUdevRules {
    state=false
    # 0 - "# local ID:" not appeared, do not pass any "KERNEL=="
    # 1 - "# local ID:" appeared, do pass one "KERNEL=="
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
    pushd $internalID
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
    if [ -z "$1" ]
    then
        rm -rf $internalId
    fi

    popd # internalId
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
            while read -r lineStored
            do
                if [[ "$line" == "$lineStored" ]]
                then
                    return 1
                fi
            done < /usr/share/flash-git/$i/repos
        done
    done < $1
    return 0
}

function burnFlash {
    # Arguments:
    #   1. device
    #   2. localId
    umount $1
    #mkfs.ext4 $argDevice -d root && echo OK || echo FAILED
    pushd /usr/share/flash-git/$2
    tmpAlias=$(cat alias)
    mkfs.vfat -n "fg_$tmpAlias" $1 && tmp=$(mktemp -d) && mount $1 $tmp && cp -rf * $tmp/ && umount $tmp && rm -rf $tmp && retval=0 || retval=1
    popd
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

function insertFakeDevice {
    ./flash-git__add.sh "$1" "$2"
    exit 0
}

function releaseFakeDevice {
    ./flash-git_remove.sh "$1"
    exit 0
}

function createFakeMedia {
    if [ -d fakeDevices/"$1" ]
    then
        echo "such directory already exists"
        exit 1
    fi
    mkdir -p fakeDevices/"$1"
	for i in idVendor idProduct serial product manufacturer
    do
        echo -n "$i: "
        read tmp
        echo "ID_$i=$tmp" >> fakeDevices/"$1"/hardware
    done
}

function showFakeMedia {
    if [ ! -r fakeDevices/"$1"/hardware ]
    then
        echo "such fake device not found"
        exit 1
    fi
    source fakeDevices/"$1"/hardware
    tmp=$(cat fakeDevices/"$1"/alias)
    echo "Alias: \"$tmp\""
    for i in idVendor idProduct serial product manufacturer
    do
        tmp=ID_$i
        echo "ID_$i=${!tmp}"
    done
}

function createSandbox {
    if [ -d sandboxes/"$1" ]
    then
        echo "such directory already exists"
        exit 1
    fi
    su $2 -c "mkdir -p sandboxes/\"$1\""
    echo -n "host id: "
    read tmp
    su $2 -c "echo $tmp > sandboxes/\"$1\"/hostid"
}

function showSandbox {
    if [ ! -r sandboxes/"$1"/hostid ]
    then
        echo "such sandbox not found"
        exit 1
    fi
    tmp=$(cat sandboxes/"$1"/hostid)
    echo "host id: $tmp"
}

function listFakeDevices {
    if [ -d fakeDevices ]
    then
        pushd fakeDevices
        for i in $(ls -1)
        do
            if [ -r "$i"/hardware ]
            then
                echo "$i"
            fi
        done
        popd
    fi
}

function listSandboxes {
    if [ -d sandboxes ]
    then
        pushd sandboxes
        for i in $(ls -1)
        do
            if [ -r "$i"/hostid ]
            then
                echo "$i"
            fi
        done
        popd
    fi
}

function removeFakeDevice {
    if [ ! -r fakeDevices/"$1"/hardware ]
    then
        echo "such fake device not found"
        exit 1
    fi
    rm -rf fakeDevices/"$1"
}

function removeSandbox {
    if [ ! -r sandboxes/"$1"/hostid ]
    then
        echo "such fake device not found"
        exit 1
    fi
    rm -rf sandboxes/"$1"
}

for i in $*
do
    #echo $i
    if [[ $i == "--free" ]]
    then
        argFree=true
        checkMediaDevice "$argFree"
    elif [[ ${i:0:10} == "--restore=" ]]
    then
        argRestore="${i:10}"
        checkMediaDevice "$argRestore"
    elif [[ ${i:0:10} == "--sandbox=" ]]
    then
        argSandbox="${i:10}"
        checkArgSandbox "$argSandbox"
    elif [[ $i == "--show-registered" ]]
    then
        argShowRegistered=true
    elif [[ ${i:0:14} == "--fake-insert=" ]]
    then
        argFakeinsert="${i:14}"
        checkFakeMedia "$argFakeinsert"
    elif [[ ${i:0:15} == "--fake-release=" ]]
    then
        argFakeRelease="${i:15}"
        checkFakeMedia "$argFakeRelease"
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
    elif [[ ${i:0:9} == "--device=" ]]
    then
        argDevice="${i:9}"
        checkMediaDevice "$argDevice"
    elif [[ ${i:0:14} == "--fake-device=" ]]
    then
        argFakeDevice="${i:14}"
        checkFakeMedia "$argFakeDevice"
    elif [[ ${i:0:8} == "--alias=" ]]
    then
        argAlias=${i:8}
    elif [[ ${i:0:21} == "--create-fake-device=" ]]
    then
        argCreateFakeDevice="${i:21}"
    elif [[ ${i:0:19} == "--show-fake-device=" ]]
    then
        argShowFakeDevice="${i:19}"
    elif [[ ${i:0:17} == "--create-sandbox=" ]]
    then
        argCreateSandbox="${i:17}"
    elif [[ ${i:0:15} == "--show-sandbox=" ]]
    then
        argShowSandbox="${i:15}"
    elif [[ ${i} == "--list-fake-devices" ]]
    then
        argListFakeDevices=true
    elif [[ ${i} == "--list-sandboxes" ]]
    then
        argListSandboxes=true
    elif [[ ${i:0:21} == "--remove-fake-device=" ]]
    then
        argRemoveFakeDevice="${i:21}"
    elif [[ ${i:0:17} == "--remove-sandbox=" ]]
    then
        argRemoveSandbox="${i:17}"
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
elif [ $argFakeinsert ]
then
    echo "fake media insert"
    insertFakeDevice "$argFakeinsert" "$argSandbox"
    exit 0
elif [ $argFakeRelease ]
then
    echo "fake media release"
    releaseFakeDevice "$argFakeRelease"
    exit 0
elif [ $argDevice ] && [ $argRepoList ]
then
    echo "initialize local repositories by media"
    checkArgRepoList "$argRepoList"
elif [ $argFakeDevice ] && [ $argRepoList ] && [ $argSandbox ]
then
    echo "initialize local repositories by media (fake mode)"
elif [ $argDevice ] && [ $argUser ] && [ $argGroup ]
then
    echo "initialize media by local repositories"
elif [ $argFakeDevice ] && [ $argUser ] && [ $argGroup ] && [ $argSandbox ]
then
    echo "initialize fake media by local repositories"
elif [ $argCreateFakeDevice ]
then
    echo "create fake device"
    createFakeMedia "$argCreateFakeDevice"
    exit 0
elif [ $argShowFakeDevice ]
then
    echo "show fake device"
    showFakeMedia $argShowFakeDevice
    exit 0
elif [ $argCreateSandbox ]
then
    echo "create sandbox"
    createSandbox "$argCreateSandbox" $argUser
    exit 0
elif [ $argShowSandbox ]
then
    echo "show sandbox"
    showSandbox "$argShowSandbox"
    exit 0
elif [ $argListFakeDevices ]
then
    echo "list fake devices"
    listFakeDevices
    exit 0
elif [ $argListSandboxes ]
then
    echo "list sandboxes"
    listSandboxes
    exit 0
elif [ $argRemoveFakeDevice ]
then
    echo "remove fake device"
    removeFakeDevice "$argRemoveFakeDevice"
    exit 0
elif [ $argRemoveSandbox ]
then
    echo "remove sandbox"
    removeSandbox "$argRemoveSandbox"
    exit 0
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
        mount $argDevice $prelmount
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
    if checkRepolistAvailable "$argRepoList"
    then
        echo "you already have registered media for at least one repository"
        exit 1
    fi
else
    tmp=$(mktemp)
    mount $argDevice $tmp && if checkRepolistAvailable $tmp/repos
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

if [[ ! -z "$argRepoList" ]]
then
	#source $hardwareFile
	#echo $ID_SERIAL

	rm -rf $workdir/root
	mkdir $workdir/root
    echo -n > $workdir/repos
    while read -r line
	do
        tmp=$(realpath "line") # get absolute path
        if [[ $tmp == "$HOME"/* ]] # replace HomeDir for "~"
        then
            t=${#HOME}
            tmp=~${tmp:$t}
        fi
        # boris here: transform path
        if [ ! -z "$argSandbox" ]
        then
            tmp=sandboxes/"$argSandbox"/"$line"
        fi
		echo "$tmp"
		repopath=$workdir/root/$(basename $tmp).git # boris e: add check for repositories names are all unique
		git init --bare --shared=true "$repopath"
		pushd "$tmp"
		git remote remove flash-git
		git remote add flash-git "$repopath"
		for branch in $(git branch | cut -c 3-)
		do
			git push --set-upstream flash-git "$branch"
		done
		git push flash-git
        # boris here
		popd # "$tmp"
	done < "$argRepoList"
	cp -L "$argRepoList" $workdir/repos # dereferencing if it's a symbolyc link
	#echo $hostid > $workdir/root/hosts

    #copy_flashgit_into_dir root
    echo $FLASH_GIT_VERSION > $workdir/flash_git_version

    if [ ! -z "$argDevice" ]
    then
        burnFlash $argDevice $localId
        rm -rf $workdir/root
    else # argFakeDevice is not null
        rm -rf fakeDevices/"$argFakeDevice"/root
        mv $workdir/root fakeDevices/"$argFakeDevice"/
        echo OK
    fi

else
    tempdir=$(mktemp -d)
    if [ ! -z "$argDevice" ]
    then
        rm -rf $workdir/root
        mkdir $workdir/root
        mount $1 $workdir/root
    else # argFakeDevice is not null
        if [ ! -d fakeDevices/"$argFakeDevice"/root ]
        then
            mkdir -p fakeDevices/"$argFakeDevice"/root
        fi
        ln -s $(pwd)/fakeDevices/"$argFakeDevice"/root $workdir/root
    fi
	#if grep -Fxq $hostid root/hosts # if $hostid existen in root/hosts
	#then
	#	echo "reinitializing? Rejected."
	#	#exit 1
	#fi

	while read -r line
	do
		echo "${underline}${line}${nounderline}":
        tmp="$line"
        if [ ! -z "$argSandbox" ]
        then
            tmp=sandboxes/"$argSandbox"/"$line"
        fi
		if [ -d "$tmp" ]
		then
			echo "Path '$line' already existen. FAILED."
			exit 1
		fi
        su ${argUser} -c "mkdir -p \"$tmp\""
		repopath=$workdir/root/"$(basename $line).git"
		git clone "$repopath" "$tmp"
		pushd "$tmp"
		git remote rename origin flash-git
		popd
		chown -R $argUser "$tmp"
		chgrp -R $argGroup "$tmp"
	done < root/repos
	#echo $hostid >> root/hosts

    if [ ! -z $argDevice ]
    then
        umount root
        rm -rf root
    else
        rm root
    fi
fi

#=====================
#exit 0

mediaPath=$(pwd)

#echo "#!/bin/bash
## flash-git version: $FLASH_GIT_VERSION
#
#if [ ! \$(id -u) -eq 0 ]
#then
#    echo Run this under ROOT only!
#    exit 1
#fi
#
#
##r=\$(mktemp -d)
##pushd \$r
#
#if [ ! -d \"$mediaPath\" ]
#then
#    echo flash-git config lost
#    exit 1
#fi
#
#pushd \"$mediaPath\"
#rm -rf root
#if [ -z \"$argDevice\" ]
#then
#    #ln -s fakeDevices/"$argFakeDevice" root
#    if [[ ! -r fakeDevices/\"\$1\"/hardware ]]
#    then
#        echo Please specify a fake device to set as your repository carrier
#        exit 1
#    fi
#    ln -s fakeDevices/\"\$1\"/root root
#else
#    if [[ ! -b \"\$1\" ]]
#    then
#        echo Please specify a device to set as your repository carrier
#        exit 1
#    fi
#    mkdir root
#    mount \"\$1\" root
#fi
#if [ ! -r root/repos ]
#then
#    echo \"\\\"repos\\\" not found\"
#    exit 1
#fi
#for oRepo in \$(cat root/repos) # boris e: read per-entire-line instead of split by space-symbols
#do
#	echo \"repo:  \$oRepo\"
#    tmp=\"\$oRepo\"
#    if [ ! -z \"$argSandbox\" ]
#    then
#        tmp=\"$(pwd)/sandboxes/\"\$2\"/\$oRepo\"
#    fi
#    pushd \"\$tmp\"
#	git pull flash-git
#	git push flash-git
#	git pull flash-git
#	popd
#done
#if [ -z \""$argDevice\"" ]
#then
#    rm root
#else
#    umount root
#    rm -rf root
#fi
#popd # $mediaPath
#
#" > flash-git__add.sh

#echo "#!/bin/bash
## flash-git version: $FLASH_GIT_VERSION
#" > flash-git__remove.sh

#chmod +x flash-git__{add,remove}.sh
#chmod +x /usr/local/bin/flash-git__{add,remove}.sh

if [ ! -f $udevRulesPath ]
then
    echo "# Edit this file ONLY via "flash-git" utility. Do not edit this manually!
" > $udevRulesPath
fi

if [ $argDevice ]
then
    addMediaToUdev $tmpHardware $localId
fi
