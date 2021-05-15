#!/bin/bash
# flash-git version: 0

# $USER is empty

source /usr/share/flash-git/flash-git__fs.sh
source /usr/share/flash-git/flash-git__hw.sh

#tmpMounted=$(mktemp -d)
tmpMounted=/usr/share/flash-git/media
tmpHardware=$(mktemp)
tmpLog=$(mktemp)
detectHardwareForMedia $1 $tmpHardware
#myMount $1 $tmpMounted
mount $1
#cp $tmpMounted/alias /home/boris/
workdir=
logPath=~/.flash-git.log # /usr/share/flash-git/log
pushd /usr/share/flash-git
	for i in $(seq 100)
	do
		if [ -d $i ]
		then
			echo 1111
			cat $tmpMounted/alias
			echo 2222
			cat $i/alias
			if [[ $(cat $tmpMounted/alias) == $(cat $i/alias) ]] && cmp -s $tmpHardware $i/hardware
			then
				if cmp -s $i/repos $tmpMounted/repos
				then
					workdir=/usr/share/flash-git/$i
				else
					echo "log about error"
					cat $i/repos
					echo "--"
					cat $tmpMounted/repos
				fi
				break
			fi
		fi
	done
popd # /usr/share/flash-git

if [ $workdir ]
then
	#rm -rf $workdir/root
	#ln -s $tmpMounted/root $workdir/root # if do so git can not push ("can not create temporary file"). Make directory and copy instead.
	echo >> "$logPath"
	date >> "$logPath"
	#ls -lh $workdir >> /usr/share/flash-git/log
	while read -r line
	do
		branch=$(git rev-parse --abbrev-ref HEAD)
		tmp="$line"
		pushd "$tmp"
		echo "
$tmp:" >> "$logPath"
		git pull flash-git &> $tmpLog
		echo "--1--"
		cat $tmpLog >> "$logPath"; echo -n > $tmpLog
		git push --set-upstream flash-git $branch &> $tmpLog
		echo "--2--"
		cat $tmpLog >> "$logPath"; echo -n > $tmpLog
		git pull flash-git &> $tmpLog
		echo "--3--"
		cat $tmpLog >> "$logPath"; echo -n > $tmpLog
		popd # "$tmp"
	done < $workdir/repos
	#ls -lh $workdir/root
	#rm -rf $workdir/root
else
	echo "log about error"
fi

umount $1
#umount $tmpMounted
rm tmpLog
rm tmpHardware
#rm -rf tmpMounted
