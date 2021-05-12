#!/bin/bash
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
	echo; echo "Please execute this script, don't source it"
	echo "(sourcing pollutes the environment with variables)."; echo
	return; fi

. _shared_objects.sh


# keyboard polling function... puts key name in $INPUT; empty if no interesting key
function GET_KEY () {

	local OLD_IFS=$IFS
	IFS=''

	INPUT=""
	read -s -N 1 KEY
	case $KEY in
	[yn])
		KEY=`echo ${KEY,,}`
		INPUT=$KEY
		until [[ -z ${KEY} ]]; do read -s -t 0.1 -N 1 KEY; done # keyboard flush
		;;
	esac

	IFS=$OLD_IFS
} # END function GET_KEY



clear
echo -e -n "$fBOLD"
echo "5 - Install up-to-date hashes"	
echo "-----------------------------"
echo -e -n "$fPLAIN"
check_request_sudo


### parse commandline parameters for grub dir
get_path_arguments


### check writability of GRUB directories
sudo test -w "${GRUB_CFG_DIR}"
if [ "$?" -ne "0" ]
then
	echo "ERROR: GRUB boot directory not writable" >&2
	EXIT_WITH_KEYPRESS
fi


### check work path, template availability
check_in_script_path

if [[ -e "../bootfiles/grub_switch_hashes" ]]
then :
else
	echo "ERROR: ../bootfiles/grub_switch_hashes path not present" >&2
	EXIT_WITH_KEYPRESS
fi


### Ask for write confirmation
echo -e "This action will install up-to-date hashes of permitted SWITCH.GRB files to ${fBOLD}${GRUB_CFG_DIR}${fPLAIN}"
echo -e "Do you want to proceed? (${fBOLD}y${fPLAIN})es / (${fBOLD}n${fPLAIN})o"

while [[ true ]]
do
	GET_KEY
	case ${INPUT} in
			"y")
				sudo rm -rf ${GRUB_CFG_DIR}/grub_switch_hashes
				sudo cp -rf ../bootfiles/grub_switch_hashes ${GRUB_CFG_DIR}/
				echo ; echo "Hashes installed." ; echo
				break
				;;
			"n")
				echo ; echo "Action canceled." ; echo
				sleep 1
				break
				;;
			"*")
				;;
	esac
done

EXIT_WITH_KEYPRESS
