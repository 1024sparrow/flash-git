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
	echo -n > /usr/share/flash-git/hardware
	for i in idVendor idProduct serial product manufacturer
	do
		var=$(udevadm info -a -n sdb | grep -m1 "ATTRS{$i}" | sed "s/^.*==\"//" | sed "s/\"$//")
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
	done < root/repos
	echo $hostid >> root/hosts



	umount root
	rm -rf root
	exit 1
fi

mediaPath=$(pwd)/root

echo "#!/bin/bash

rm -rf /mnt/flash-git
mkdir /mnt/flash-git
echo $1 > /mnt/flash-git/1
echo $2 > /mnt/flash-git/2
" > /usr/local/bin/flash-git__add.sh

echo "#!/bin/bash

rm -rf /mnt/flash-git
" > /usr/local/bin/flash-git__remove.sh

chmod +x /usr/local/bin/flash-git__{add,remove}.sh

#echo "KERNEL==\"sd[b-z]*\", ATTRS{idVendor}==\"090c\", ATTRS{idProduct}==\"1000\", ATTRS{serial}==\"1306030911800573\", ATTRS{product}==\"Silicon-Power4G\", ATTRS{manufacturer}==\"UFD 2.0\", RUN+=\"/usr/local/bin/flash-git__add.sh /dev/%k%n\"" > /etc/udev/rules.d/flash-git.rules

echo "KERNEL==\"sd[b-z]*\", ATTRS{idVendor}==\"${ID_idVendor}\", ATTRS{idProduct}==\"${ID_idProduct}\", ATTRS{serial}==\"${ID_serial}\", ATTRS{product}==\"${ID_product}\", ATTRS{manufacturer}==\"ID_manufacturer\", RUN+=\"/usr/local/bin/flash-git__add.sh /dev/%k%n\"" > /etc/udev/rules.d/10-flash-git.rules

udevadm control --reload-rules && udevadm trigger
