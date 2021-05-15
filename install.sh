#!/bin/bash

curDir="$(pwd)"

if [ ! $(id -u) -eq 0 ]
then
	echo Run this under ROOT only!
	exit 1
fi

if [ -f /usr/local/bin/flash-git ] || [ -d /usr/share/flash-git ]
then
	echo "already installed. Error."
	exit 1
fi

if [ -d /usr/share/bash-completion/completions ]
then
	if [ -f /usr/share/bash-completion/completions/flash-git ]
	then
		echo "such bash completion already exists. Error."
		exit 1
	fi
fi

pushd /usr/local/bin
ln -s "$curDir"/flash-git.sh flash-git
popd

if [ -d /usr/share/bash-completion/completions ]
then
	pushd /usr/share/bash-completion/completions
	ln -s "$curDir"/bash-completion flash-git
	popd
else
	echo "bash-completions not set for flash-git because of bash-completion not found on the system"
fi

mkdir /usr/share/flash-git
mkdir /usr/share/flash-git/media

for i in add remove fs hw
do
	ln -s $(pwd)/flash-git__${i}.sh /usr/share/flash-git/
done
