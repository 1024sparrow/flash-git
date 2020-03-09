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

if [[ -r $2 ]]
then
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
		git clone --bare --shared "$i"/.git root/$(basename $i).git
	done
	cp -L $2 root/repos
	echo $hostid > root/hosts

	mkfs.ext4 $1 -d root && echo OK || echo FAILED
	rm -rf root
	echo FINISHED

else
	# echo Prease specify file with repositories list
	echo not implemented
	rm -rf root
	mkdir root
	mount $1 root
	hosts=$(cat root/hosts) # boris here
	umount root
	exit 1
fi


#mkdir /usr/share/flash-git
#echo "${target_hardware}" > /usr/share/flash-git/hardware

#echo "${target_hardware}"
#a=$(udevadm info --export --name $1)
#b=$(cat /usr/share/flash-git/hardware)
#if [[ "$a" == "$b" ]]
#then
#	echo true
#else
#	echo false
#fi

# ==========================================
#echo "#!/bin/bash

#mkdir /mnt/flash-git
#" > /usr/local/bin/flash-git__add.sh

#echo "#!/bin/bash

#rm -rf /mnt/flash-git
#" > /usr/local/bin/flash-git__remove.sh

#chmod +x /usr/local/bin/flash-git__{add,remove}.sh

#echo "ACTION=="add" KERNEL=="sd[b-z]*" RUN+="/usr/bin/flash-git__add.sh"
#" > /etc/udev/rules.d/flash-git.rules
