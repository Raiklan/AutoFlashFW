#!/bin/bash

#Variables
dir_marker_tmp=/tmp/marker-tmp
index_file=${dir_marker_tmp}/index.html
log_file=${dir_marker_tmp}/upgrade.log
URL="http://vm-rdgbuild-03.itron.com/FW_Builds/MCU/DINICMeshGlobal/development/"
JLINK=/opt/SEGGER/JLink/JLinkExe

mkdir -p ${dir_marker_tmp}

#Functions 

function download_latest_build() {
	wget "$URL" -O ${index_file}
	# Grep the number of the build and the date it was uploaded to the website to get the latest FW
	latest_build=$(grep -Eo '[0-9]{7}/</a></td><td align="right">[0-9]{4}-[0-9]{2}-[0-9]{2}' ${index_file} | sed 's/\(.*\)\/<\/a><\/td><td align="right">\([0-9-]*\)/\2 \1/' | sort -r | head -1 | cut -d ' ' -f 2)
	fw_url="${URL}/${latest_build}/bin/APPLICATION_BINARY.elf.bin"
	curl -O "$fw_url"
	echo "Latest build: $latest_build" >> ${log_file}
}

echo "FW $latest_build successfuly downloaded" > ${log_file}
#Now Flash the FW in the device
function flash_firmware() {
	${JLINK} -device STM32U575AI -if SWD -speed 4000 -autoconnect 1 -CommanderScript flash.jlink >> ${log_file}
	echo "Firmware flashing complete." >> ${log_file}
}

function check_dependacies() {
	# Check if JLinkExe is available
	if ! command -v ${JLINK} &> /dev/null
	then
	    echo "JLinkExe could not be found. Please install it." >> ${log_file}
	    return 1
	fi
	# Check for curl
	if ! command -v curl &> /dev/null
	then
	    echo "curl could not be found. Please install it." >> ${log_file}
	    return 1
	fi

	# Check for wget
	if ! command -v wget &> /dev/null
	then
	    echo "wget could not be found. Please install it." >> ${log_file}
	    return 1
	fi
}

check_dependacies || exit 1

download_latest_build

flash_firmware

echo "Script Completed" >> ${log_file}
