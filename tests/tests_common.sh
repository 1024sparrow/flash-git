#!/bin/bash

if [ $(id -u) -eq 0 ]
then
    echo Do not run this under ROOT!
    exit 1
fi

function s {
    su root -c "$*"
}

declare -i show_enumerated__num=1
function show_enumerated {
    if [ -z help ]
    then
        echo
    fi
    echo "$show_enumerated__num. "$*
    show_enumerated__num+=1
}
