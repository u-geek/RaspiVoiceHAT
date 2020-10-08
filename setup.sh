#!/bin/bash

TITLE="AOIDE RaspiVoiceHAT setup tools"
BACKTITLE="UGEEK WORKSHOP [ ugeek.aliexpress.com | ukonline2000.taobao.com ]"
driver_version="5.4.51"
driver_installed=false
driver_enabled=false
firmware_hash="390477bf6dc80dddfafcd3682b4e026e96cfc4d7"

driver_filename="raspivoicehat_"$driver_version".tar.gz"
dtoverlay=""
file_config="/boot/config.txt"

# Get kernel version
function get_kernel_version(){
	kernel_version=$(uname -r)
	IFS='-' read -ra kernel_version <<< "$kernel_version"
}

# Get Driver installed
function get_driver_installed(){
	if [ -f "/lib/modules/$kernel_version+/kernel/sound/soc/bcm/snd-soc-wm8960-soundcard.ko" ]; then
		driver_installed=true
	fi
}

# Get kernel version
function get_driver_enabled(){
	driver_in_config="cat /boot/config.txt | grep dtoverlay=raspivoicehat" 
	if [ -n "$driver_in_config" ]; then
		driver_enabled=true
	fi
}

# Install newest kernel
function kernel_install(){
	echo "Install Raspberry PI Kernel "$driver_version
	if [ ! -f "/usr/bin/rpi-update" ]; then
		apt update
		apt install binutils curl
		curl -L --output /usr/bin/rpi-update https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update && sudo chmod +x /usr/bin/rpi-update
	fi
	UPDATE_SELF=0 SKIP_BACKUP=1 rpi-update $firmware_hash
}

# Install driver
function driver_install(){
	cp drivers/$driver_filename /
	cd /
	tar zxvf $driver_filename
	rm /$driver_filename
}

# Deploy driver
function deploy_driver(){
	depmod -b / -a $driver_version+
	depmod -b / -a $driver_version-v7+
	depmod -b / -a $driver_version-v7l+
	depmod -b / -a $driver_version-v8+
}

# Enable driver
function driver_enable(){
	sed -i 'raspivoicehat/d' $file_config
	echo "dtoverlay=raspivoicehat" >> $file_config
}

# Disable driver
function driver_disable(){
	sed -i 'raspivoicehat/d' $file_config
}

# Run demo_run
function demo_run(){
	python3 examples/demo.py
}

# Reboot prompt
function reboot_prompt(){
	if [ -z "$1" ]; then
		return
	fi
	if (whiptail --title "$TITLE" \
	--backtitle "$BACKTITLE" \
	--yes-button "Reboot" --no-button "NO" \
	--yesno "Reboot system to apply" 10 60) then
		sync
		reboot
	else
		return
	fi
}

# Check privileges
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

# Get kernel version
get_kernel_version
get_driver_installed
get_driver_enabled

# Main loop
while true
do
	OPTION=$(whiptail --title "$TITLE(V$driver_version)" \
	--menu "RaspiVoiceHAT Config Tool." \
	--backtitle "$BACKTITLE" \
	--cancel-button "Exit" 18 60 10 \
	"1" "Install Driver"
	"2" "Remove Driver" \
	"3" "Demo" \
	"E" "Exit" \
	3>&1 1>&2 2>&3)
	case $OPTION in
		1)
		if [ "$driver_version" != "$kernel_version" ]; then
			kernel_install
		fi
		if [ ! $driver_enabled ] ; then
			driver_install
			deploy_driver
		fi
		if [ ! $driver_enabled ]; then
			driver_enable
		fi
		reboot_prompt
		;;
		2)
		driver_disable
		reboot_prompt
		;;
		3)
		demo_run
		;;
		"E")
		exit 1
		;;
	esac
done

