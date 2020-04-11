#!/bin/bash

declare -i FLASH_GIT_VERSION=0

#underline=`tput smul`
#nounderline=`tput rmul`
#bold=`tput bold`
#normal=`tput sgr0`

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
  $ flash-git --device=<DEVICE> --alias=<ALIAS> --repo-list=<REPO_LIST> # boris here 1 ("alias" added)
  $ flash-git --fake-device=<FAKE_DEVICE> --repo-list=<REPO_LIST> --alias=<ALIAS> --sandbox=<SANDBOX> # boris here 2 ("alias" added)

  initialize local repositories by media:
  $ flash-git --device=<DEVICE> --user=<USER> --group=<GROUP>
  $ flash-git --fake-device=<FAKE_DEVICE> --user=<USER> --group=<GROUP> --sandbox=<SANDBOX>

  unchain media from local repositories:
  $ flash-git --free
    flash-git will ask you for media to free

  restore media via local repositories
  $ flash-git --restore=<DEVICE> # boris here 4
  $ flash-git --restore=<FAKE_DEVICE> # boris here 5

  show using devices and repositories:
  $ flash-git --show-registered # boris here 3

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

# boris e: add checking for curent directory is the flash-git repository root

allArgs=(
    argSandbox
    argFakeinsert
    argFakeRelease
    argUser
    argGroup
    argRepoList
    argDevice
    argFakeDevice
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
    "argDevice argRepoList"
    "argFakeDevice argRepoList argSandbox"
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
    for i in $(cat "$1")
    do
        tmp=$i
        if [ ! -z "$argSandbox" ]
        then
            tmp=sandboxes/"$argSandbox"/$i
        fi
        if [ ! -d "$tmp" ]
        then
            echo "repository not found: $i"
            exit 1
        fi
        pushd "$tmp"
        git status &> /dev/null || (echo "directory \"$i\" not initialized as git-repository"; exit 1)
        popd
    done
}

function checkMediaDevice {
    if [ ! -b "$1" ]
    then
        echo "\"$1\" is not valid media device"
        exit 1
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
    if [[ ${i:0:10} == "--sandbox=" ]]
    then
        argSandbox="${i:10}"
        checkArgSandbox "$argSandbox"
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

if [ $argFakeinsert ]
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

if [[ -r "$argRepoList" ]]
then
	#rm -rf /usr/share/flash-git
	echo -n > hardware
    if [ ! -z "$argDevice" ]
    then
        for i in idVendor idProduct serial product manufacturer
        do
            var=$(udevadm info -a -n $1 | grep -m1 "ATTRS{$i}" | sed "s/^.*==\"//" | sed "s/\"$//")
            echo ID_$i=$var >> hardware
        done
    else # argFakeDevice is not null
        cp fakeDevices/"$argFakeDevice"/hardware hardware
    fi

	source hardware
	echo $ID_SERIAL


	rm -rf root
	mkdir root
	for i in $(cat "$argRepoList")
	do
        tmp=$i
        if [ ! -z "$argSandbox" ]
        then
            tmp=sandboxes/"$argSandbox"/$i
        fi
		echo $tmp
		repopath=$(pwd)/root/$(basename $tmp).git
		git init --bare --shared=true "$repopath"
		pushd $tmp
		git remote remove flash-git
		git remote add flash-git "$repopath"
		for branch in $(git branch | cut -c 3-)
		do
			git push --set-upstream flash-git "$branch"
		done
		git push flash-git
		popd
	done
	cp -L "$argRepoList" root/repos # dereferencing if it's a symbolyc link
	echo $hostid > root/hosts

    #copy_flashgit_into_dir root
    echo FLASH_GIT_VERSION > root/flash_git_version

    if [ ! -z "$argDevice" ]
    then
        mkfs.ext4 $1 -d root && echo OK || echo FAILED
        rm -rf root
    else # argFakeDevice is not null
        rm -rf fakeDevices/"$argFakeDevice"/root
        mv root fakeDevices/"$argFakeDevice"/
        echo OK
    fi

else
    if [ ! -z "$argDevice" ]
    then
        rm -rf root
        mkdir root
        mount $1 root
    else # argFakeDevice is not null
        if [ ! -d fakeDevices/"$argFakeDevice"/root ]
        then
            mkdir -p fakeDevices/"$argFakeDevice"/root
        fi
        ln -s fakeDevices/"$argFakeDevice"/root ./
    fi
	if grep -Fxq $hostid root/hosts # if $hostid existen in root/hosts
	then
		echo "reinitializing? Rejected."
		#exit 1
	fi

	echo "TODO: print error if any from list already existen; create paths to repos and pull from flash-drive"
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
		#mkdir -p "$tmp" # boris e: we change ownership only for leaf directory not for whole path. It is incorrect.
        su ${argUser} -c "mkdir -p \"$tmp\""
		repopath=$(pwd)/root/"$(basename $line).git"
		git clone "$repopath" "$tmp"
		pushd "$tmp"
		git remote rename origin flash-git
		popd
		chown -R $argUser "$tmp"
		chgrp -R $argGroup "$tmp"
	done < root/repos
	echo $hostid >> root/hosts

    if [ ! -z $argDevice ]
    then
        umount root
        rm -rf root
    else
        rm root
    fi
fi

mediaPath=$(pwd)

echo "#!/bin/bash
# flash-git version: $FLASH_GIT_VERSION

if [ ! \$(id -u) -eq 0 ]
then
    echo Run this under ROOT only!
    exit 1
fi


#r=\$(mktemp -d)
#pushd \$r

if [ ! -d \"$mediaPath\" ]
then
    echo flash-git config lost
    exit 1
fi

pushd \"$mediaPath\"
rm -rf root
if [ -z \"$argDevice\" ]
then
    #ln -s fakeDevices/"$argFakeDevice" root
    if [[ ! -r fakeDevices/\"\$1\"/hardware ]]
    then
        echo Please specify a fake device to set as your repository carrier
        exit 1
    fi
    ln -s fakeDevices/\"\$1\"/root root
else
    if [[ ! -b \"\$1\" ]]
    then
        echo Please specify a device to set as your repository carrier
        exit 1
    fi
    mkdir root
    mount \"\$1\" root
fi
if [ ! -r root/repos ]
then
    echo \"\\\"repos\\\" not found\"
    exit 1
fi
for oRepo in \$(cat root/repos) # boris e: read per-entire-line instead of split by space-symbols
do
	echo \"repo:  \$oRepo\"
    tmp=\"\$oRepo\"
    if [ ! -z \"$argSandbox\" ]
    then
        tmp=\"$(pwd)/sandboxes/\"\$2\"/\$oRepo\"
    fi
    pushd \"\$tmp\"
	git pull flash-git
	git push flash-git
	git pull flash-git
	popd
done
if [ -z \""$argDevice\"" ]
then
    rm root
else
    umount root
    rm -rf root
fi
popd # $mediaPath

" > flash-git__add.sh

echo "#!/bin/bash
# flash-git version: $FLASH_GIT_VERSION
" > flash-git__remove.sh

chmod +x flash-git__{add,remove}.sh
#chmod +x /usr/local/bin/flash-git__{add,remove}.sh

if [ ! -z $argDevice ]
then
    mv flash-git__add.sh /usr/local/bin/flash-git__add.sh
    mv flash-git__remove.sh /usr/local/bin/flash-git__remove.sh
    #echo "KERNEL==\"sd[b-z]*\", ATTRS{idVendor}==\"090c\", ATTRS{idProduct}==\"1000\", ATTRS{serial}==\"1306030911800573\", ATTRS{product}==\"Silicon-Power4G\", ATTRS{manufacturer}==\"UFD 2.0\", RUN+=\"/usr/local/bin/flash-git__add.sh /dev/%k%n\"" > /etc/udev/rules.d/flash-git.rules
    echo "KERNEL==\"sd[b-z]*\", ATTRS{idVendor}==\"${ID_idVendor}\", ATTRS{idProduct}==\"${ID_idProduct}\", ATTRS{serial}==\"${ID_serial}\", ATTRS{product}==\"${ID_product}\", ATTRS{manufacturer}==\"ID_manufacturer\", RUN+=\"/usr/local/bin/flash-git__add.sh /dev/%k%n\"" > /etc/udev/rules.d/10-flash-git.rules
    udevadm control --reload-rules && udevadm trigger
fi
