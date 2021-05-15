#!/bin/bash

function myMkfs {
	# Arguments:
	# 1. Device
	# 2. Content directory
	# 3. Label
	# 4. UUID

	local uuidFormated=$4
	#local mountDir=/usr/share/flash-git/media
	uuidFormated=${uuidFormated:0:4}-${uuidFormated:4}
	echo "UUID=$uuidFormated $mountDir vfat user,umask=000,utf8,noauto 0 0" >> /etc/fstab
	echo "++++++++++++++++"
	ls $2 -lh
	echo "++++++++++++++++++++++++++++++++"
	mkfs.vfat -F 32 -n "$3" -i $4 $1 &&
		echo "+1" &&
		su boris -c "mount $1" &&
		echo "+2" &&
		su boris -c "cp -rf $2/{alias,flags,flash_git_version,hardware,repos,root} $mountDir/" &&
		echo "+3" &&
		su boris -c "umount $1" &&
		echo "+4" &&
		retval=0 ||
		retval=1
}
