#!/bin/bash

# First download the nightly build .bin
dir_marker_tmp=/tmp/marker-tmp

echo $dir_marker_tmp
index_file=${dir_marker_tmp}/index.html
log_file=${dir_marker_tmp}/upgrade.log
URL="http://vm-rdgbuild-03.itron.com/FW_Builds/MCU/DINICMeshGlobal/development/"
if [[ ! -d ${dir_marker_tmp} ]]; then mkdir ${dir_marker_tmp}; fi

if [[ -f ${index_file} ]]; then echo "${index_file} exists"; fi

wget "$URL" -O ${index_file}

# Grep the number of the build and the date it was uploaded to the website to get the latest FW
latest_build=$(grep -Eo '[0-9]{7}/</a></td><td align="right">[0-9]{4}-[0-9]{2}-[0-9]{2}' ${index_file} | sed 's/\(.*\)\/<\/a><\/td><td align="right">\([0-9-]*\)/\2 \1/' | sort -r | head -1 | cut -d ' ' -f 2)

echo $latest_build

fw_url="${URL}/${latest_build}/bin/APPLICATION_BINARY.elf.bin"

curl -O "$fw_url"

echo "FW $latest_build successfuly downloaded" > ${log_file}
#Now Flash the FW in the device

JLINK=/opt/SEGGER/JLink/JLinkExe
# Check if JLinkExe is available
if ! command -v ${JLINK} &> /dev/null
then
    echo "JLinkExe could not be found. Please install it." >> ${log_file}
    exit 1
fi

${JLINK} -device STM32U575AI -if SWD -speed 4000 -autoconnect 1 -CommanderScript flash.jlink >> ${log_file}

echo "Firmware flashing complete." >> ${log_file}
