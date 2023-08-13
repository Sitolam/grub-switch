#!/bin/bash


# terminal format macros
fPLAIN="\e[0m"
fBOLD="\e[1m"
fUNBOLD="\e[22m"
fDIM="\e[2m"
fUNDIM="\e[22m"
fREVERSE="\e[7m"
# color format macros
fgDEFAULT="\e[39m" ; bgDEFAULT="\e[49m"
fgBLACK="\e[30m" ; fgRED="\e[31m" ; fgGREEN="\e[32m" ; fgYELLOW="\e[33m"
fgBLUE="\e[34m" ; fgMAGENTA="\e[35m" ; fgCYAN="\e[36m" ; fgLIGHTGRAY="\e[37m"
fgDARKGRAY="\e[90m" ; fgLIGHTRED="\e[91m" ; fgLIGHTGREEN="\e[92m" ; fgLIGHTYELLOW="\e[93m"
fgLIGHTBLUE="\e[94m" ; fgLIGHTMAGENTA="\e[95m" ; fgLIGHTCYAN="\e[96m" ; fgWHITE="\e[97m"
bgBLACK="\e[40m" ; bgRED="\e[41m" ; bgGREEN="\e[42m" ; bgYELLOW="\e[43m"
bgBLUE="\e[44m" ; bgMAGENTA="\e[45m" ; bgCYAN="\e[46m" ; bgLIGHTGRAY="\e[47m"
bgDARKGRAY="\e[100m" ; bgLIGHTRED="\e[101m" ; bgLIGHTGREEN="\e[102m" ; bgLIGHTYELLOW="\e[103m"
bgLIGHTBLUE="\e[104m" ; bgLIGHTMAGENTA="\e[105m" ; bgLIGHTCYAN="\e[106m" ; bgWHITE="\e[107m"

# bash exit codes
SUCCESS=0
ERROR_NO_SUCH_FILE_OR_DIR=1
ERROR_PERMISSION_DENIED=13
ERROR_NO_SUCH_COMMAND=127


# clean leave
function EXIT_WITH_KEYPRESS () {

	echo
	echo "Press any key to return to continue."
	echo

	local OLD_IFS=$IFS
	IFS=''

	read -s -N 1 KEY
	until [[ -z ${KEY} ]]; do read -s -t 0.1 -N 1 KEY; done # keyboard flush

	IFS=$OLD_IFS

	exit "$SUCCESS" # means won't leave CONFIGURE script
} # END function EXIT_WITH_KEYPRESS


function EXIT_ON_FAIL {
	if [ "$?" -ne "0" ] # failure on paths
	then
		exit "$?"
	fi	
}


function check_tools_availability {

	TOOLS_ALL_THERE=true

	# GNU coreutils
	ACHECK=$(cat --version 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo
		echo -e "${fBOLD}cat${fUNBOLD} tool missing."
		echo -e "Please install ${fBOLD}GNU coreutils${fUNBOLD} before continuing."
		TOOLS_ALL_THERE=false
	fi

	# sudo
	ACHECK=$(sudo --version 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo
		echo -e "${fBOLD}sudo${fUNBOLD} command missing."
		echo -e "Please install ${fBOLD}sudo${fUNBOLD} package as root before continuing."
		echo -e "Afterwards, please give a non-root user ${fBOLD}sudo${fUNBOLD} privileges"
		echo -e "and run GRUBswitch tools as that user. Doing all boot"
		echo -e "manipulations as a full root user invites trouble."
		TOOLS_ALL_THERE=false
	fi

	# which
	ACHECK=$(which cat 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo
		echo -e "${fBOLD}which${fUNBOLD} tool missing."
		echo -e "Please install ${fBOLD}which${fUNBOLD} package before continuing."
		TOOLS_ALL_THERE=false
	fi

	# grep
	ACHECK=$(grep --version 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo
		echo -e "${fBOLD}grep${fUNBOLD} tool missing."
		echo -e "Please install ${fBOLD}grep${fUNBOLD} package before continuing."
		TOOLS_ALL_THERE=false
	fi

	# sed
	ACHECK=$(sed --version 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo
		echo -e "${fBOLD}sed${fUNBOLD} tool missing."
		echo -e "Please install ${fBOLD}sed${fUNBOLD} package before continuing."
		TOOLS_ALL_THERE=false
	fi

	# Bash version 4 or higher
	ACHECK=$(/bin/bash --version | head -n 1 | sed 's@^[^0-9]*\([0-9]\).*@\1@' 2>/dev/null)
	if [ "$ACHECK" -lt 4 ]
	then
		echo
		echo -e "${fBOLD}bash${fUNBOLD} shell is version 3.x or lower."
		echo -e "Please install ${fBOLD}bash${fUNBOLD} version 4.x or higher before continuing."
		TOOLS_ALL_THERE=false
	fi	

	# mount
	ACHECK=$(mount --version 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo
		echo -e "${fBOLD}mount${fUNBOLD} tool missing."
		echo -e "Please install package containing ${fBOLD}mount${fUNBOLD} command before continuing."
		TOOLS_ALL_THERE=false
	fi

	# umount
	ACHECK=$(umount --version 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo
		echo -e "${fBOLD}umount${fUNBOLD} tool missing."
		echo -e "Please install package containing ${fBOLD}umount${fUNBOLD} command before continuing."
		TOOLS_ALL_THERE=false
	fi

	# lsblk
	ACHECK=$(lsblk --version 2>/dev/null)
	if [ "$?" -ne 0 ]
	then
		echo
		echo -e "${fBOLD}lsblk${fUNBOLD} tool missing."
		echo -e "Please install package containing ${fBOLD}lsblk${fUNBOLD} command before continuing."
		TOOLS_ALL_THERE=false
	fi


	return
}


function initial_sudo_acquisition {

	clear
	sudo -K
	echo "Most GRUBswitch actions require sudo (super user) access"
	echo "- please provide your password"
	echo

	local sudostate=$(sudo whoami 2>/dev/null)

	if [ "$sudostate" = "root" ]
	then
		echo
		LAST_SUDO_STATE="ACTIVE"
		return "$SUCCESS"
	else
		echo
		echo "ERROR: Failed to acquire sudo access; exiting tool." >&2
		echo
		LAST_SUDO_STATE="INACTIVE"
		return "$ERROR_PERMISSION_DENIED"
	fi
}


function check_sudo_reacquire_or_exit {
	local sudostate=$(sudo -n whoami 2>/dev/null)

	if [ "$sudostate" = "root" ]
	then
		LAST_SUDO_STATE="ACTIVE"
		return "$SUCCESS"
	else
		echo
		echo "sudo (super user) access timed out; password required again."
		echo
			sudostate=$(sudo whoami 2>/dev/null)
			if [ "$sudostate" = "root" ]
			then
				echo
				LAST_SUDO_STATE="ACTIVE"
				return "$SUCCESS"
			else
				echo
				echo "ERROR: Failed to reacquire sudo access; exiting tool." >&2
				echo
				LAST_SUDO_STATE="INACTIVE"
				return "$ERROR_PERMISSION_DENIED"
			fi
	fi
}


function get_path_arguments {

	OPTIND=1

	while getopts ":g:s:b:" callarg
	do
		case ${callarg} in
			g)
				GRUB_CFG_DIR=${OPTARG}
				;;
			s)
				CFG_SCRIPTS_DIR=${OPTARG}
				;;
			b)
				BLS_CONF_DIR=${OPTARG}
				;;
			*)
				;;
		esac
	done
}


function find_update_grub_tool {

	check_sudo_reacquire_or_exit
	EXIT_ON_FAIL

	### find tool paths
	UPDATEGRUB=`sudo which update-grub  2>/dev/null`
	UPDATEGRUB2=`sudo which update-grub2  2>/dev/null`
	GRUBMKCONFIG=`sudo which grub-mkconfig  2>/dev/null`
	GRUBMKCONFIG2=`sudo which grub2-mkconfig  2>/dev/null`	
}


function run_update_grub_tool {

	check_sudo_reacquire_or_exit
	EXIT_ON_FAIL

	if [ -z "$UPDATEGRUB" ]
	then
		if [ -z "$UPDATEGRUB2" ]
		then
			if [ -z "$GRUBMKCONFIG" ]
			then
				if [ -z "$GRUBMKCONFIG2" ]
				then
					echo -e "ERROR: No ${fBOLD}update-grub${fPLAIN} or ${fBOLD}grub-mkconfig${fPLAIN} tool was found."
					EXIT_WITH_KEYPRESS
				else
					sudo ./_update-grub2.sh "${GRUB_CFG_DIR}/grub.cfg"
				fi
			else
				sudo ./_update-grub.sh "${GRUB_CFG_DIR}/grub.cfg"
			fi
		else
			sudo update-grub2
		fi
	else
		sudo update-grub
	fi

}

function GET_KEY () {

	local OLD_IFS=$IFS
	IFS=''

	INPUT=""
	read -s -N 1 KEY
	case $KEY in
	[1-9])
		INPUT=$KEY
		until [[ -z ${KEY} ]]; do read -s -t 0.1 -N 1 KEY; done # keyboard flush
		;;
	[a-fnqyA-F])
		KEY=`echo ${KEY,,}`
		INPUT=$KEY
		until [[ -z ${KEY} ]]; do read -s -t 0.1 -N 1 KEY; done # keyboard flush
		;;
	$'\n')
		INPUT="Enter"
		until [[ -z ${KEY} ]]; do read -s -t 0.1 -N 1 KEY; done # keyboard flush
		;;
	$'\177')
		INPUT="Backspace"
		until [[ -z ${KEY} ]]; do read -s -t 0.1 -N 1 KEY; done # keyboard flush
		;;
	$'\e')
		INPUT="Escape"
		read -s -t 0.1 -N 1 KEY # read second char after \e
		if [[ -n ${KEY} ]]
		then
		INPUT=""
			if [[ ${KEY} = '[' ]]
			then
				read -s -t 0.1 -N 1 KEY # read third char after \e[
				case ${KEY} in
					'D')	INPUT="CursorLeft" ;;
					'C')	INPUT="CursorRight" ;;
					'A')	INPUT="CursorUp" ;;
					'B')	INPUT="CursorDown" ;;
					'H')	INPUT="Pos1" ;;
					'F')	INPUT="End" ;;
					# 4-char cases
					[2356])
					    if [[ ${KEY} = '5' ]]; then INPUT="PageUp"; fi
						if [[ ${KEY} = '6' ]]; then INPUT="PageDown"; fi
						if [[ ${KEY} = '3' ]]; then INPUT="Delete"; fi
						if [[ ${KEY} = '2' ]]; then INPUT="Insert"; fi
						# common check for '~' 
						read -s -t 0.1 -N 1 KEY
						if [[ ${KEY} != '~' ]]
						then INPUT=""
						fi
						;;
				esac
			fi
		fi
		until [[ -z ${KEY} ]]; do read -s -t 0.1 -N 1 KEY; done # keyboard flush
		;;
	esac

	IFS=$OLD_IFS
} # END function GET_KEY

