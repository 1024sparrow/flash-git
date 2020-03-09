#!/bin/bash

if [ -z $1 ]
then
	echo Please specify a device to set as your repository carrier
	exit 1
fi

if [ ! $(id -u) -eq 0 ]
then
    echo Run this under ROOT only!
    exit 1
fi

echo > /usr/share/flash-git/hardware
for i in "E: ID_VENDOR_ID=" "E: ID_MODEL_ID=" "E: ID_FS_TYPE=" "E: DEVTYPE=" "E: ID_SERIAL="
do
var=$(udevadm info --export --name $1 | grep "$i")
#echo $i "-->" ${var:${#i}}
echo ${i:3}${var:${#i}} >> /usr/share/flash-git/hardware
done

source /usr/share/flash-git/hardware

echo $ID_SERIAL

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
