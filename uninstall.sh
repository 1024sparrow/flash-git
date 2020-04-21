#!/bin/bash

if [ ! $(id -u) -eq 0 ]
then
    echo Run this under ROOT only!
    exit 1
fi

rm /usr/local/bin/flash-git
rm -rf /usr/share/flash-git

tmp=/usr/share/bash-completion/completions/flash-git
if [ -f $tmp ]
then
    rm $tmp
fi

tmp=/etc/udev/rules.d/10-flash-git.rules
if [ -f $tmp ]
then
    rm $tmp
    udevadm control --reload-rules && udevadm trigger
fi
