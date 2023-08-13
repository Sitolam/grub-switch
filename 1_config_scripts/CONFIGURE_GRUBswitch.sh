#!/bin/bash
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
	echo; echo "Please execute this script, don't source it"
	echo "(sourcing pollutes the environment with variables)."; echo
	return; fi

if [[ "`pwd`" =~ ^.*/1_config_scripts$ ]]; then : ; else
	echo -e "ERROR: Script not started from \e[1m1_config_scripts\e[0m directory" >&2
	echo ; exit 13 ; fi  ## ERROR_PERMISSION_DENIED

. _shared_objects.sh


#### CONFIGURE_GRUBswitch.sh ####
## Master script that controls, sequences all GRUBswitch configuration scripts

### FUNCTIONS

function show_status_menu {

	clear

	## check sudo state
	check_sudo_reacquire_or_exit
	EXIT_ON_FAIL

	clear

	echo -e -n "$fBOLD"
	echo "GRUBswitch Configuration Menu"
	echo "============================="
	echo -e -n "$fPLAIN"


	echo

	echo -e -n "$fBOLD"
	echo "Status of files:"
	echo "----------------"
	echo -e -n "$fPLAIN"
	echo

	echo -e -n "$fgDEFAULT"
	# grubmenu_all_entries.lst
	echo "Extracted list of GRUB menu entries  (../bootfiles/grubmenu_all_entries.lst): "
	if [[ -f "../bootfiles/grubmenu_all_entries.lst" ]]
	then
		moddate=`stat -c %Y ../bootfiles/grubmenu_all_entries.lst`
		echo "-> last extracted at" `date -d @"${moddate}" +"%d %b %Y - %H:%M:%S"`
	else
		echo "-> not present"
	fi
	echo

	# /bootfiles/boot.[1..f]
	echo "Generated boot files for regular flash drives (../bootfiles/boot.[1..f]):"
	moddate=""
	for j in 1 2 3 4 5 6 7 8 9 a b c d e f
	do
		if [[ -f "../bootfiles/boot.${j}/SWITCH.GRB" ]]
		then
			moddate=`stat -c %Y "../bootfiles/boot.${j}/SWITCH.GRB"`
		fi
	done
	if [ -z "$moddate" ]
	then
		echo "-> not present"
	else
		echo "-> last updated at" `date -d @"${moddate}" +"%d %b %Y - %H:%M:%S"`
	fi

	# /bootfiles/.entries.txt
	echo "Generated boot file for GRUBswitch USB device (../bootfiles/.entries.txt):"
	if [[ -f "../bootfiles/.entries.txt" ]]
	then
		moddate=`stat -c %Y ../bootfiles/.entries.txt`
		echo "-> last updated at" `date -d @"${moddate}" +"%d %b %Y - %H:%M:%S"`
	else
		echo "-> not present"
	fi
	echo
	echo -e -n "$fgDEFAULT"

	# grub_switch_hashes/*
	echo -e -n "$fgCYAN"
	echo "Permitted SWITCH.GRB file hashes  (${GRUB_CFG_DIR}grub_switch_hashes/*):"
	sudo test -e "${GRUB_CFG_DIR}/grub_switch_hashes/"
	if [ "$?" -eq "0" ]	
	then
		moddate=`sudo stat -c %Y ${GRUB_CFG_DIR}/grub_switch_hashes/`
		echo "-> last updated at" `date -d @"${moddate}" +"%d %b %Y - %H:%M:%S"`
	else
		echo "-> not present (no permission checking)"
	fi
	echo
	echo -e -n "$fgDEFAULT"

	# grub.cfg
	echo -e -n "$fgGREEN"
	echo "GRUB menu config file  (${GRUB_CFG_DIR}grub.cfg):"
	sudo test -f "${GRUB_CFG_DIR}/grub.cfg"
	if [ "$?" -eq "0" ]	
	then
		moddate=`sudo stat -c %Y ${GRUB_CFG_DIR}/grub.cfg`
		echo "-> last modified at" `date -d @"${moddate}" +"%d %b %Y - %H:%M:%S"`

		CURR_GRUBCFG_VER=`sudo cat ${GRUB_CFG_PATH} | grep GRUBswitch_script`

		if [ -z "$CURR_GRUBCFG_VER" ]
		then
			echo "   No GRUBswitch code included"
		else
			CURR_MODSCR_VER=`cat modifier_script/99_grub_switch | grep GRUBswitch_script`
			if [ "$CURR_GRUBCFG_VER" = "$CURR_MODSCR_VER" ]
			then
				echo "   contains up-to-date GRUBswitch code"
			else
				echo "   contains outdated GRUBswitch code"
			fi
		fi
	else
		echo "-> not present (that's a problem)"
	fi
	echo
	echo -e -n "$fgDEFAULT"



}



### UNSET/INIT RELEVANT VARIABLES



### TODO: CHECKING TOOL AVAILABILITY
check_tools_availability

if $TOOLS_ALL_THERE
then
	:
else
	echo
	echo "ERROR: Required tools missing; exiting..." >&2
	echo
	exit "$ERROR_NO_SUCH_COMMAND"
fi


### get sudo
LAST_SUDO_STATE="INACTIVE"
initial_sudo_acquisition
EXIT_ON_FAIL

### check bootfiles availability
if [[ -e "../bootfiles/" ]]
then :
else
	echo "ERROR: ../bootfiles/ path not present" >&2
	exit "$ERROR_NO_SUCH_FILE_OR_DIR"
fi

if [[ -f "../bootfiles/template" ]]
then :
else
	echo "ERROR: ../bootfiles/template not present" >&2
	exit "$ERROR_NO_SUCH_FILE_OR_DIR"
fi



### parse commandline parameters for grub dirs, check existence/access
get_path_arguments $@
EXIT_ON_FAIL



check_sudo_reacquire_or_exit
EXIT_ON_FAIL
bash _1_extract_menuentries.sh -g $GRUB_CFG_DIR -b ${BLS_CONF_DIR}
EXIT_ON_FAIL

clear
echo -e -n "$fBOLD"
echo "2 - Configure and generate bootfiles"	
echo "------------------------------------"
echo -e -n "$fPLAIN"
echo
bash _2_configure_and_generate_bootfiles.sh

clear
echo -e -n "$fBOLD"
echo "7 - Install GRUBswitch into grub.cfg"	
echo "------------------------------------"
echo -e -n "$fPLAIN"
echo

check_sudo_reacquire_or_exit
EXIT_ON_FAIL

sudo cp ./modifier_script/99_grub_switch /boot/grub/
sudo chmod +x /boot/grub/99_grub_switch
echo ; echo "GRUBswitch modifier script installed" ; echo

sudo nixos-rebuild switch

