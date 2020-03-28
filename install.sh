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

\$sudo ./install.sh <ПУТЬ_ДО_УСТРОЙСТВА_ФЛЕШКИ> --repo-list=<путь_А>

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

\$sudo ./install.sh <ПУТЬ_ДО_УСТРОЙСТВА_ФЛЕШКИ> --user=\$USER --group=\$USER

${underline}Дополнительные аргументы для отладки${nounderline}

Для тестирования и отладки данного скрипта поддерживается возможность работы не с реальной файловой системой и реальными флешками, а с песочницами и снимками флешек.
Песочница - это директория, в которой находится файл "hostid" с фейковым идентификатором хоста.
Снимок флешки - это директория, в которой находится файл с информацией о флешке (производитель, серийный номер и всё такое)

Данным скриптом поддерживаются следующие аргументы для отладки и тестирования:

--sandbox=<ПЕСОЧНИЦА>
	В указанной выше директории должен находиться файл ${bold}hostid${normal} с фейковым идентификатором хоста

--fake-insert <СНИМОК_ФЛЕШКИ>
	Проиграть имитацию того, что была вставлена флешка

--fake-release <СНИМОК_ФЛЕШКИ>
	Проиграть имитацию того, что флешка была извлечена (аппаратно)
"
		exit 0
	fi
done

if [ ! $(id -u) -eq 0 ]
then
    echo Run this under ROOT only!
    exit 1
fi

argSandbox=
argFakeinsert=
argFakeRelease=
argUser=
argGroup=
argRepoList=

function checkArgSandbox {
    echo checkSandbox
}

function checkArgFakeInsert {
    echo checkArgFakeInsert
}

function checkArgFakeRelease {
    echo checkArgFakeRelease
}

function checkArgUser {
    echo checkArgUser
}

function checkArgGroup {
    echo checkArgGroup
}

function checkArgRepoList {
    echo checkArgRepoList
}

for i in $*
do
    echo $i
    if [[ ${i:0:10} == "--sandbox=" ]]
    then
        argSandbox="${i:10}"
        checkArgSandbox argSandbox
    elif [[ ${i:0:14} == "--fake-insert=" ]]
    then
        argFakeinsert="${i:14}"
    elif [[ ${i:0:15} == "--fake-release=" ]]
    then
        argFakeRelease="${i:15}"
    elif [[ ${i:0:7} == "--user=" ]]
    then
        argUser="${i:7}"
    elif [[ ${i:0:8} == "--group=" ]]
    then
        argGroup="${i:8}"
    elif [[ ${i:0:12} == "--repo-list=" ]]
    then
        argRepoList="${i:12}"
    else
        echo "unexpected argument: $i
Call \"./install.sh --help\" for details"
        exit 1
    fi
done

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
