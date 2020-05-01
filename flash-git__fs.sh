#!/bin/bash

function myMkfs {
    # Arguments:
    # 1. Device
    # 2. Content directory

    # mkfs.vfat -n "fg_$tmpAlias" $1 && tmp=$(mktemp -d) && myMount $1 $tmp && cp -rf * $tmp/ && umount $tmp && rm -rf $tmp && retval=0 || retval=1

    mkfs.ext4 $1 -d $2
}

function myMount {
    # Arguments:
    # 1. Device
    # 2. Directory

    # mount $1 -tvfat -o"iocharset=utf8" $2

    mount $1 $2
}
