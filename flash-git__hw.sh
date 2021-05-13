#!/bin/bash

function detectHardwareForMedia {
	# arguments:
	#	1. device
	#	2. file path to write hardware info
	for i in idVendor idProduct serial product manufacturer
	do
		var=$(udevadm info -a -n $1 | grep -m1 "ATTRS{$i}" | sed "s/^.*==\"//" | sed "s/\"$//")
		echo "ID_$i=\"$var\"" >> $2
	done
}
