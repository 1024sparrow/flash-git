#!/bin/bash

if [ $(id -u) -eq 0 ]
then
    echo Do not run this under ROOT!
    exit 1
fi

function s {
    su root -c $*
}

mkdir gameplay
pushd gameplay

s flash-git --create-sandbox=sb1 || exit 1
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

s flash-git --create-fake-device=fd1 || exit 1

s flash-git --fake-device=fd1 --repo-list=repolist -sandboxe=sb1 || exit 1

s flash-git --create-sandbox=sb2 || exit 1

s flash-git --fake-device=fd1 --user=$USER --group=$USER --sandbox=sb2 || exit 1

echo FINISHED
