#!/bin/bash

source ../tests_common.sh

if [[ $1 == "--help" ]]
then
    help=on
fi

if [ -z $help ]
then
    r=$(mktemp -d)
    echo "all files will create at directory \"$r\""
    pushd $r
fi

show_enumerated "Create sandbox \"sb1\". Initialize two repositories there."
if [ -z $help ]
then
    s flash-git --create-sandbox=sb1 --user=$USER || exit 1
    echo -n > repolist
    pushd sandboxes/sb1
    for i in repo1 repo2
    do
        mkdir $i
        echo $i >> ../../repolist
        pushd $i
        git init
        echo $i > $i
        git add $i
        git commit -m"first commit"
        popd
    done
    popd # sandboxes/sb1
fi

show_enumerated "Create fake device \"fd1\""
if [ -z $help ]
then
    s flash-git --create-fake-device=fd1 || exit 1
fi

show_enumerated "Initialize device \"fd1\" by local repositories in \"sb1\""
if [ -z $help ]
then
    s flash-git --fake-device=fd1 --repo-list=repolist --sandbox=sb1 || exit 1
fi

show_enumerated "Create sandbox \"sb2\""
if [ -z $help ]
then
    s flash-git --create-sandbox=sb2 --user=$USER || exit 1
fi

show_enumerated "Initialize local repositories in \"sb1\" via device \"fd1\""
if [ -z $help ]
then
    s flash-git --fake-device=fd1 --user=$USER --group=$USER --sandbox=sb2 || exit 1
fi

if [ -z $help ]
then
    popd # $r
fi

if [ -z $help ]
then
    echo FINISHED
fi
