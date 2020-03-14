#!/bin/bash

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

hostid=$(hostid)

underline=`tput smul`
nounderline=`tput rmul`
bold=`tput bold`
normal=`tput sgr0`

if [[ -r $2 ]]
then
	rm -rf /usr/share/flash-git
	mkdir /usr/share/flash-git
	echo > /usr/share/flash-git/hardware
	for i in "E: ID_VENDOR_ID=" "E: ID_MODEL_ID=" "E: DEVTYPE=" "E: ID_SERIAL="
	do
		var=$(udevadm info --export --name $1 | grep "$i")
		echo ${i:3}${var:${#i}} >> /usr/share/flash-git/hardware
	done

	source /usr/share/flash-git/hardware
	echo $ID_SERIAL


	rm -rf root
	mkdir root
	for i in $(cat $2)
	do
		echo $i
		repopath=$(pwd)/root/$(basename $i).git
		git init --bare "$repopath" # boris here: init, remote add, git push
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
	cp -L $2 root/repos
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
	done < root/repos
	echo $hostid >> root/hosts



	umount root
	rm -rf root
	exit 1
fi



#a=$(udevadm info --export --name $1)
#b=$(cat /usr/share/flash-git/hardware)
#if [[ "$a" == "$b" ]]
#then
#	echo true
#else
#	echo false
#fi

# ==========================================

mediaPath=$(pwd)/root

echo "#!/bin/bash
" > /usr/local/bin/flash-git__add.sh

#echo "#!/bin/bash

echo "#!/bin/bash
" > /usr/local/bin/flash-git__remove.sh

chmod +x /usr/local/bin/flash-git__{add,remove}.sh

echo 'ACTION=="add" KERNEL=="sd[b-z]*" RUN+="/usr/bin/flash-git__add.sh"
' > /etc/udev/rules.d/flash-git.rules
