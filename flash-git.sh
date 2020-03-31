#!/bin/bash

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
  $ ./flash-git.git --help
  no matter if in addon to "--help" would be any other arguments - they will be ignored

  initialize local repositories by media:
  $ ./flash-git.git --device=<DEVICE> --repo-list=<REPO_LIST>
  $ ./flash-git.git --fake-device=<FAKE_DEVICE> --repo-list=<REPO_LIST> --sandbox=<SANDBOX>

  initialize media by local repositories:
  $ ./flash-git.git --device=<DEVICE> --user=<USER> --group=<GROUP>
  $ ./flash-git.git --fake-device=<FAKE_DEVICE> --user=<USER> --group=<GROUP> --sandbox=<SANDBOX>

  create fake device:
  $ ./flash-git.git --create-fake-device=<FAKE_DEVICE>
  $ ./flash-git.git --show-fake-device=<FAKE_DEVICE>
  $ ./flash-git.git --create-sandbox=<SANDBOX>
  $ ./flash-git.git --show-sandbox=<SANDBOX>
  $ ./flash-git.git --list-fake-devices
  $ ./flash-git.git --list-sandboxes
  $ ./flash-git.git --remove-fake-device=<FAKE_DEVICE>
  $ ./flash-git.git --remove-sandbox=<SANDBOX>



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

function checkArgSandbox {
    if [ ! -d "$1" ]
    then
        echo "Not such directory: $1"
        exit 1
    fi
    if [ ! -r "$1"/hostid ]
    then
        echo "Directory \"$1\" does not present a sandbox"
        exit 1
    fi
}

function checkFakeMedia {
    echo checkArgFakeInsert
    if [ ! -r "$1"/hardware ]
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
        if [ ! -d $i ]
        then
            echo "repository not found: $i"
            exit 1
        fi
        pushd
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

function createFakeMedia {
    if [ -d "$1" ]
    then
        echo "such directory already exists"
        exit 1
    fi
    mkdir "$1"
	for i in idVendor idProduct serial product manufacturer
    do
        echo -n "$i: "
        read tmp
        echo "ID_$i=$tmp" >> "$1"/hardware
    done
}

function showFakeMedia {
    if [ ! -r "$1"/hardware ]
    then
        echo "such fake device not found"
        exit 1
    fi
    source "$1"/hardware
    for i in idVendor idProduct serial product manufacturer
    do
        tmp=ID_$i
        echo "ID_$i=${!tmp}"
    done
}

function createSandbox {
    if [ -d "$1" ]
    then
        echo "such directory already exists"
        exit 1
    fi
    mkdir "$1"
    echo -n "host id: "
    read tmp
    echo $tmp > "$1"/hostid
}

function showSandbox {
    if [ ! -r "$1"/hostid ]
    then
        echo "such sandbox not found"
        exit 1
    fi
    tmp=$(cat "$1"/hostid)
    echo "host id: $tmp"
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
        checkArgRepoList "$argRepoList"
    elif [[ ${i:0:9} == "--device=" ]]
    then
        argDevice="${i:9}"
        checkMediaDevice "$argDevice"
    elif [[ ${i:0:14} == "--fake-device=" ]]
    then
        argFakeDevice="${i:14}"
        checkFakeMedia "argFakeDevice"
    elif [[ ${i:0:21} == "--create-fake-device=" ]]
    then
        argCreateFakeDevice="${i:21}"
        createFakeMedia "$argCreateFakeDevice"
        exit 0
    elif [[ ${i:0:19} == "--show-fake-device=" ]]
    then
        argShowFakeDevice="${i:19}"
        showFakeMedia $argShowFakeDevice
        exit 0
    elif [[ ${i:0:17} == "--create-sandbox=" ]]
    then
        argCreateSandbox="${i:17}"
        createSandbox "$argCreateSandbox"
        exit 0
    elif [[ ${i:0:15} == "--show-sandbox=" ]]
    then
        argShowSandbox="${i:15}"
        showSandbox "$argShowSandbox"
        exit 0
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
Call \"./flash-git.git --help\" for details"
        exit 1
    fi
done

validArgsCombinations=(
    "argFakeinsert"
    "argFakeRelease"
    "argCreateFakeDevice"
    "argShowFakeDevice"
    "argListFakeDevices"
    "argRemoveFakeDevice"
    "argCreateSandbox"
    "argShowSandbox"
    "argListSandboxes"
    "argRemoveSandbox"
    "argDevice argRepoList"
    "argFakeDevice argRepoList argSandbox"
    "argDevice argUser argGroup"
    "argFakeDevice argUser argGroup argSandbox"
)
declare -i iComb=0
declare -i counter=0
ok=false
while [ $iComb -lt ${#validArgsCombinations[@]} ]
do
    counter=0
    ok=true
    for i in ${allArgs[@]}
    do
        found=false
        for ii in ${validArgsCombinations[$iComb]}
        do
            if [[ $i == $ii ]]
            then
                if [ ! -z ${!i} ]
                then
                    counter+=1
                    found=true
                fi
            fi
        done
        if [[ $found == false ]]
        then
            if [ ! -z ${!i} ]
            then
                ok=false
                continue
            fi
        fi
    done
    if [[ $ok == true ]]
    then
        break
    fi

    tmp=${validArgsCombinations[$iComb]}
    if [ $counter -eq ${#tmp[@]} ]
    then
        if [[ $ok == true ]]
        then
            break
        fi
        ok=true
    fi
    iComb+=1
done

if [[ $ok == false ]]
then
    echo "incorrect arguments combination. See "--help" for details."
    exit 1
fi

if [ $argFakeinsert ]
then
    echo "fake media insert"
elif [ $argFakeRelease ]
then
    echo "fake media release"
elif [ $argDevice ] && [ $argRepoList ]
then
    echo "initialize local repositories by media"
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
elif [ $argShowFakeDevice ]
then
    echo "show fake device"
elif [ $argCreateSandbox ]
then
    echo "create sandbox"
elif [ $argShowSandbox ]
then
    echo "show sandbox"
elif [ $argListFakeDevices ]
then
    echo "list fake devices"
elif [ $argListSandboxes ]
then
    echo "list sandboxes"
elif [ $argRemoveFakeDevice ]
then
    echo "remove fake device"
elif [ $argRemoveSandbox ]
then
    echo "remove sandbox"
fi

echo "NOT IMPLEMENTED"
exit 0

if [[ ! -b $1 ]]
then
	echo Please specify a device to set as your repository carrier
	exit 1
fi

hostid=$(hostid)

if [[ -r $2 ]]
then
	rm -rf /usr/share/flash-git
	mkdir /usr/share/flash-git
	echo -n > /usr/share/flash-git/hardware
	for i in idVendor idProduct serial product manufacturer
	do
		var=$(udevadm info -a -n $1 | grep -m1 "ATTRS{$i}" | sed "s/^.*==\"//" | sed "s/\"$//")
		echo ID_$i=$var >> /usr/share/flash-git/hardware
	done

	source /usr/share/flash-git/hardware
	echo $ID_SERIAL


	rm -rf root
	mkdir root
	for i in $(cat $2)
	do
		echo $i
		repopath=$(pwd)/root/$(basename $i).git
		git init --bare --shared=true "$repopath"
		pushd $i
		git remote remove flash-git
		git remote add flash-git "$repopath"
		for branch in $(git branch | cut -c 3-)
		do
			git push --set-upstream flash-git "$branch"
		done
		git push flash-git
		popd
	done
	cp -L $2 root/repos # dereferencing if it's a symbolyc link
	echo $hostid > root/hosts

	mkfs.ext4 $1 -d root && echo OK || echo FAILED
	rm -rf root
	echo FINISHED

else
	# echo Prease specify file with repositories list
	rm -rf root
	mkdir root
	mount $1 root
	if grep -Fxq $hostid root/hosts # if $hostid existen in root/hosts
	then
		echo "reinitializing? Rejected."
		#exit 1
	fi

	echo "TODO: print error if any from list already existen; create paths to repos and pull from flash-drive"
	while read -r line
	do
		echo "${underline}${line}${nounderline}":
		if [ -d "$line" ]
		then
			echo "Path '$line' already existen. FAILED."
			exit 1
		fi
		mkdir -p $line
		repopath=$(pwd)/root/$(basename $line).git
		git clone "$repopath" $line
		pushd "$line"
		git remote rename origin flash-git
		popd
		chown -R boris "$line"
		chgrp -R boris "$line"
	done < root/repos
	echo $hostid >> root/hosts



	umount root
	rm -rf root
	exit 1
fi

mediaPath=$(pwd)/root

echo "#!/bin/bash

if [ ! $(id -u) -eq 0 ]
then
    echo Run this under ROOT only!
    exit 1
fi

if [[ ! -b $1 ]]
then
	echo Please specify a device to set as your repository carrier
	exit 1
fi

#r=/home/boris/opt/flash-git
r=$(mktemp -d)
pushd $r
rm -rf root
mkdir root
mount $1 root
for oRepo in $(cat root/repos)
do
	echo "repo: " $oRepo
	pushd $oRepo
	git pull flash-git
	git push flash-git
	git pull flash-git
	popd
done
umount root
rm -rf root
popd
" > /usr/local/bin/flash-git__add.sh

echo "#!/bin/bash
" > /usr/local/bin/flash-git__remove.sh

chmod +x /usr/local/bin/flash-git__{add,remove}.sh

#echo "KERNEL==\"sd[b-z]*\", ATTRS{idVendor}==\"090c\", ATTRS{idProduct}==\"1000\", ATTRS{serial}==\"1306030911800573\", ATTRS{product}==\"Silicon-Power4G\", ATTRS{manufacturer}==\"UFD 2.0\", RUN+=\"/usr/local/bin/flash-git__add.sh /dev/%k%n\"" > /etc/udev/rules.d/flash-git.rules

echo "KERNEL==\"sd[b-z]*\", ATTRS{idVendor}==\"${ID_idVendor}\", ATTRS{idProduct}==\"${ID_idProduct}\", ATTRS{serial}==\"${ID_serial}\", ATTRS{product}==\"${ID_product}\", ATTRS{manufacturer}==\"ID_manufacturer\", RUN+=\"/usr/local/bin/flash-git__add.sh /dev/%k%n\"" > /etc/udev/rules.d/10-flash-git.rules

udevadm control --reload-rules && udevadm trigger
