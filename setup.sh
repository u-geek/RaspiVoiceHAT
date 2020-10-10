#!/bin/bash

TITLE="AOIDE RaspiVoiceHAT setup tools"
BACKTITLE="UGEEK WORKSHOP [ ugeek.aliexpress.com | ukonline2000.taobao.com ]"
driver_version="5.4.51"
driver_installed="no"
driver_enabled="no"
firmware_hash="390477bf6dc80dddfafcd3682b4e026e96cfc4d7"

driver_filename="raspivoicehat_"$driver_version".tar.gz"
dtoverlay=""
file_config="/boot/config.txt"

SOFTWARE_LIST="git python3-pip libportaudio2"

# Install required
function install_sys_required(){
	apt update
	apt -y install $SOFTWARE_LIST
}

function install_python_required(){
	pip3 install Adafruit-Blinka adafruit-circuitpython-bitbangio adafruit-circuitpython-busdevice apa102-pi pyaudio
}

# Get kernel version
function get_kernel_version(){
	kernel_version=$(uname -r)
	IFS='-' read -ra kernel_version <<< "$kernel_version"
}

# Get Driver installed
function get_driver_installed(){
	#echo "/lib/modules/$kernel_version+/kernel/sound/soc/bcm/snd-soc-wm8960-soundcard.ko"
	if [ -f "/lib/modules/$kernel_version+/kernel/sound/soc/bcm/snd-soc-wm8960-soundcard.ko" ]; then
		driver_installed="yes"
	else
		driver_installed="no"
	fi
}

# Get kernel version
function get_driver_enabled(){
	driver_in_config=$(cat /boot/config.txt | grep dtoverlay=raspivoicehat)
	if [ -n "$driver_in_config" ]; then
		driver_enabled="yes"
	else
		driver_enabled="no"
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

function driver_uninstall(){
	rm /lib/modules/$kernel_version+/kernel/sound/soc/bcm/snd-soc-wm8960-soundcard.ko
	rm /lib/modules/$kernel_version+/kernel/sound/soc/codecs/snd-soc-wm8960.ko
	rm /lib/modules/$kernel_version-v7+/kernel/sound/soc/bcm/snd-soc-wm8960-soundcard.ko
	rm /lib/modules/$kernel_version-v7+/kernel/sound/soc/codecs/snd-soc-wm8960.ko
	rm /lib/modules/$kernel_version-v7l+/kernel/sound/soc/bcm/snd-soc-wm8960-soundcard.ko
	rm /lib/modules/$kernel_version-v7l+/kernel/sound/soc/codecs/snd-soc-wm8960.ko
	rm /lib/modules/$kernel_version-v8+/kernel/sound/soc/bcm/snd-soc-wm8960-soundcard.ko
	rm /lib/modules/$kernel_version-v8+/kernel/sound/soc/codecs/snd-soc-wm8960.ko
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
	echo "Deploy modules."
	depmod -b / -a $driver_version+
	depmod -b / -a $driver_version-v7+
	depmod -b / -a $driver_version-v7l+
	depmod -b / -a $driver_version-v8+
}

# Disable driver
function driver_disable(){
	sed -i '/^dtparam=audio=on/d' $file_config
	sed -i '/^dtoverlay=raspivoicehat/d' $file_config
}

# Enable driver
function driver_enable(){
	driver_disable
	echo "dtoverlay=raspivoicehat" >> $file_config
}

# Run demo_run
function demo_run(){
	python3 examples/runcolorcycle_blinkt.py
}

# Reboot prompt
function reboot_prompt(){
	if (whiptail --title "$TITLE" \
	--backtitle "$BACKTITLE" \
	--yes-button "Reboot" --no-button "NO" \
	--yesno "Reboot system to apply settings?" 10 60) then
		sync
		reboot
	else
		return
	fi
}

function get_driver_status(){
	get_kernel_version
	echo "Kernel version:$kernel_version"
	get_driver_installed
	echo "Driver installed:$driver_installed"
	get_driver_enabled
	echo "Driver enabled:$driver_enabled"
}

function menu_main(){
	OPTION=$(whiptail --title "$TITLE($driver_version)" \
		--menu "RaspiVoiceHAT Config Tool." \
		--backtitle "$BACKTITLE" \
		--cancel-button "Exit" 18 60 10 \
		"1" "Install Driver" \
		"2" "Remove Driver" \
		"3" "Demo" \
		"E" "Exit" \
		3>&1 1>&2 2>&3)
		case $OPTION in
			1)
			get_driver_status
			if [ "$driver_version" != "$kernel_version" ]; then
				echo "Update kernel $driver_version now"
				kernel_install
			else 
				echo "Skip kernel update."
			fi
			if [ "$driver_installed" == "yes" ] ; then
				echo "Skip driver install."
			else
				echo "Driver isn't installed,enabled it now."
				driver_install
				deploy_driver
			fi
			if [ "$driver_enabled" == "yes" ]; then
				echo "Skip driver enable."
			else
				driver_enable
				echo "Enable driver in $file_config."
			fi
			echo "Reboot prompt."
			reboot_prompt
			;;
			2)
			get_driver_status
			if [ "$driver_installed" == "yes" ]; then
				echo "Remove drivers."
				driver_uninstall
				deploy_driver
			fi
			echo "Disable driver."
			if [ "$driver_enabled" == "yes" ]; then
				echo "Disable driver."
				driver_disable
			fi
			echo "Reboot prompt."
			reboot_prompt
			;;
			3)
			menu_demo
			;;
			"E")
			echo "Exit config tool."
			exit 1
			;;
		esac
}

function menu_demo(){
	OPTION=$(whiptail --title "$TITLE($driver_version)" \
		--menu "RaspiVoiceHAT Config Tool." \
		--backtitle "$BACKTITLE" \
		--cancel-button "Exit" 18 60 10 \
		"1" "Install required packages" \
		"2" "LED ColorCycle" \
		"3" "Record and Play" \
		"E" "Exit" \
		3>&1 1>&2 2>&3)
		case $OPTION in
			1)
			echo "Check and install systemd required packages"
			install_sys_required
			install_python_required
			menu_demo
			;;
			2)
			echo "LED ColorCycle"
			python3 examples/runcolorcycle_blinkt.py
			menu_demo
			;;
			3)
			echo ""
			echo "Record and Play"
			echo ""
			echo "Press top button to record a voice,release to play the voice"
			echo ""
			echo "Break demo with Ctrl + C"
			echo ""
			python3 examples/recordandplay.py
			menu_demo
			;;
			"E")
			menu_main
			;;
		esac
}

# Check privileges
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

get_driver_status

# Main loop
while true
do
	menu_main
done

