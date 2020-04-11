#!/bin/bash

#underline=`tput smul`
#nounderline=`tput rmul`
#bold=`tput bold`
#normal=`tput sgr0`

for i in $*
do
	if [[ "$i" == "--help" || $i == "-h" ]]
	then
		echo "
--help
    show this help

--device=<xx>
    set flash-device xx

--fake-device=<xx>
    set fake-device xx

--user=<user>
    set user to set new local repository ownership

--group=<group>
    set group to set new local repository ownership

--sandbox=<ПЕСОЧНИЦА>
	В указанной выше директории должен находиться файл ${bold}hostid${normal} с фейковым идентификатором хоста

--fake-insert=<СНИМОК_ФЛЕШКИ>
	Проиграть имитацию того, что была вставлена флешка

--fake-release=<СНИМОК_ФЛЕШКИ>
	Проиграть имитацию того, что флешка была извлечена (аппаратно)

--create-fake-device=<FAKE_DEVICE>
    create and initialize directory that can be in future pointed as fake device

--show-fake-device=<FAKE_DEVICE>
    show info about pointed fake device

--create-sandbox=<SANDBOX>
    create and initialize directory that can be in future pointed as a sandbox

--show-sandbox=<SANDBOX>
    show info about pointed sandbox

--list-fake-devices
    list all fake-devices names

--list-sandboxes
    list all sandboxes names

--remove-fake-device=<FAKE_DEVICE>
    remove fake device

--remove-sandbox=<SANDBOX>
    remove sandbox
"
		exit 0
	fi
done

#if [ ! $(id -u) -eq 0 ]
#then
    #echo Run this under ROOT only!
    #exit 1
#fi

allArgs=(
    argSandbox
    argFakeinsert
    argFakeRelease
    argUser
    argGroup
    argRepoList
    argDevice
    argFakeDevice
    argCreateFakeDevice
    argShowFakeDevice
    argCreateSandbox
    argShowSandbox
    argListFakeDevices
    argListSandboxes
    argRemoveFakeDevice
    argRemoveSandbox
)

for i in $*
do
    #echo $i
    if [[ ${i:0:10} == "--sandbox=" ]]
    then
        argSandbox="${i:10}"
        #checkArgSandbox "$argSandbox"
    elif [[ ${i:0:14} == "--fake-insert=" ]]
    then
        argFakeinsert="${i:14}"
        #checkFakeMedia "$argFakeinsert"
    elif [[ ${i:0:15} == "--fake-release=" ]]
    then
        argFakeRelease="${i:15}"
        #checkFakeMedia "$argFakeRelease"
    elif [[ ${i:0:7} == "--user=" ]]
    then
        argUser="${i:7}"
        #checkArgUser "$argUser"
    elif [[ ${i:0:8} == "--group=" ]]
    then
        argGroup="${i:8}"
        #checkArgGroup "$argGroup"
    elif [[ ${i:0:12} == "--repo-list=" ]]
    then
        argRepoList="${i:12}"
    elif [[ ${i:0:9} == "--device=" ]]
    then
        argDevice="${i:9}"
        #checkMediaDevice "$argDevice"
    elif [[ ${i:0:14} == "--fake-device=" ]]
    then
        argFakeDevice="${i:14}"
        #checkFakeMedia "$argFakeDevice"
    elif [[ ${i:0:21} == "--create-fake-device=" ]]
    then
        argCreateFakeDevice="${i:21}"
    elif [[ ${i:0:19} == "--show-fake-device=" ]]
    then
        argShowFakeDevice="${i:19}"
    elif [[ ${i:0:17} == "--create-sandbox=" ]]
    then
        argCreateSandbox="${i:17}"
    elif [[ ${i:0:15} == "--show-sandbox=" ]]
    then
        argShowSandbox="${i:15}"
    elif [[ ${i} == "--list-fake-devices" ]]
    then
        argListFakeDevices=true
    elif [[ ${i} == "--list-sandboxes" ]]
    then
        argListSandboxes=true
    elif [[ ${i:0:21} == "--remove-fake-device=" ]]
    then
        argRemoveFakeDevice="${i:21}"
    elif [[ ${i:0:17} == "--remove-sandbox=" ]]
    then
        argRemoveSandbox="${i:17}"
    else
        echo "unexpected argument: $i
Call \"./flash-git --help\" for details"
        exit 1
    fi
done

function checkArguments {
    validArgsCombinations=(
        "argFakeinsert argSandbox"
        "argFakeRelease argSandbox"
        "argCreateFakeDevice"
        "argShowFakeDevice"
        "argListFakeDevices"
        "argRemoveFakeDevice"
        "argCreateSandbox argUser"
        "argShowSandbox"
        "argListSandboxes"
        "argRemoveSandbox"
        "argDevice argRepoList"
        "argFakeDevice argRepoList argSandbox"
        "argDevice argUser argGroup"
        "argFakeDevice argUser argGroup argSandbox"
    )
    declare -i iComb=0
    declare -i counter=0
    declare -i allcounter=0
    #return
    while [ $iComb -lt ${#validArgsCombinations[@]} ]
    do
        allcounter=0
        counter=0
        br=false
        for i in ${allArgs[@]}
        do
            if [ ! -z ${!i} ]
            then
                exists=false
                for ii in ${validArgsCombinations[$iComb]}
                do
                    #echo "$i****$ii"
                    if [[ $i == $ii ]]
                    then
                        exists=true
                    fi
                done
                if [[ $exists == false ]]
                then
                    br=true
                fi
            fi
        done
        if [[ $br == true ]]
        then
            iComb+=1
            continue
        fi
        for i in ${validArgsCombinations[$iComb]}
        do
            allcounter+=1
        done
        for i in ${allArgs[@]}
        do
            for ii in ${validArgsCombinations[$iComb]}
            do
                if [[ $i == $ii ]]
                then
                    if [ ! -z ${!i} ]
                    then
                        counter+=1
                    fi
                fi
            done
        done
        echo "${validArgsCombinations[$iComb]}: $allcounter::$counter"
        if [ $allcounter -eq $counter ]
        then
            return
        fi
        iComb+=1
    done

    echo "incorrect arguments combination. See \"--help\" for details."
    exit 1
}

checkArguments

if [ $argFakeinsert ]
then
    echo "fake media insert"
    #insertFakeDevice "$argFakeinsert" "$argSandbox"
    #exit 0
elif [ $argFakeRelease ]
then
    echo "fake media release"
    #releaseFakeDevice "$argFakeRelease"
    #exit 0
elif [ $argDevice ] && [ $argRepoList ]
then
    echo "initialize local repositories by media"
    #checkArgRepoList "$argRepoList"
elif [ $argFakeDevice ] && [ $argRepoList ] && [ $argSandbox ]
then
    echo "initialize local repositories by media (fake mode)"
elif [ $argDevice ] && [ $argUser ] && [ $argGroup ]
then
    echo "initialize media by local repositories"
elif [ $argFakeDevice ] && [ $argUser ] && [ $argGroup ] && [ $argSandbox ]
then
    echo "initialize fake media by local repositories"
elif [ $argCreateFakeDevice ]
then
    echo "create fake device"
    #createFakeMedia "$argCreateFakeDevice"
    #exit 0
elif [ $argShowFakeDevice ]
then
    echo "show fake device"
    #showFakeMedia $argShowFakeDevice
    #exit 0
elif [ $argCreateSandbox ]
then
    echo "create sandbox"
    #createSandbox "$argCreateSandbox" $argUser
    #exit 0
elif [ $argShowSandbox ]
then
    echo "show sandbox"
    #showSandbox "$argShowSandbox"
    #exit 0
elif [ $argListFakeDevices ]
then
    echo "list fake devices"
    #listFakeDevices
    #exit 0
elif [ $argListSandboxes ]
then
    echo "list sandboxes"
    #listSandboxes
    #exit 0
elif [ $argRemoveFakeDevice ]
then
    echo "remove fake device"
    #removeFakeDevice "$argRemoveFakeDevice"
    #exit 0
elif [ $argRemoveSandbox ]
then
    echo "remove sandbox"
    #removeSandbox "$argRemoveSandbox"
    #exit 0
fi

echo "CONFIRMED. Arguments:"
for i in ${allArgs[@]}
do
    echo "$i: ${!i}"
done
