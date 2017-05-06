#!/bin/bash
#
## Piet's Host ## - ©2017, https://piets-host.de
#
# Tested on:
# CentOS 6.8 & 7.3,
# Ubuntu 12.04, 14.04, 16.04,
# Debian 7 & 8,
# Fedora 23 & 25,
# openSUSE Leap 42.1
#

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
# disable user input
stty -echo
clear
##################################
######   DEFAULT VAR START   #####
##################################

#	Uncomment if you want to set the database root password (useful,
#	if you want to install multiple instances of Nextcloud)
#database_root='P@s$w0rd!'

url1="http://example.com"
ncname="my_nextcloud"
dbhost=localhost
dbtype=mysql
rootuser='root'
html='/var/www/html' # full installation path
folder='nextcloud1'

# E-mail
email="mail@example.com"
smtpauth="LOGIN"
smtpport="587"
smtpname="admin@example.com"
smtpsec="tls"
smtppwd="password1234!"
smtpauthreq=1

# Others
displayname='true'
rlchannel='stable'
memcache='APCu'
maintenance='false'
singleuser='false'
skeleton='none'
default_language='de'
enable_avatars='true'
rewritebase='false'

################################
######   DEFAULT VAR END   #####
################################

red='\e[31m'
green='\e[32m'
yellow='\e[33m'
reset='\e[0m'
redbg='\e[41m'
lightred='\e[91m'
blue='\e[34m'
cyan='\e[36m'
ugreen='\e[4;32m'

show_help() {
cat << EOF

 Usage: ${0##*/} [-v VERSION] [-n NAME]...
 You can specify some variables before script run.
 E.g. you can set the Nextcloud version or the
 MySQL root password. If no option is set, the
 script will use default variables.

	-h --help	display this help and exit
	-v --version	specify Nextcloud Version (e.g. 10.0.0)
	-p --password	sets the MySQL root password. Type -p "P@s§"
	-r --root	sets the MySQL root user
	-m --mysqlhost	sets the MySQL Host
	-n --name	sets the Nextcloud name, used for Database
	-u --url	sets the URL for Nextcloud installation
	-d --directory	sets the full installation path
	-f --folder sets the desired folder (example.com/folder). May be empty
	-s --smtp	setup SMTP during script run (Type -s "y" or -s "n")
	-a --apps setup additionals apps during run (Type -a "y" or -a "n")
	
EOF
}

while :; do
    case $1 in
        -h|-\?|--help)   # Call a "show_help" function , then exit.
        	show_help
			stty echo
            exit
            ;;
        -v|--version)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                version="$2"
                shift
            else
                printf $redbg'ERROR: "--version" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
        -p|--password)
			if [ -n "$2" ]; then
				database_root="$2"
				shift
			else
                printf $redbg'ERROR: "--password" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
		-r|--root)
			if [ -n "$2" ]; then
				dbruser="$2"
				shift
			else
                printf $redbg'ERROR: "--root" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
		-m|--mysqlhost)
			if [ -n "$2" ]; then
				dbhost="$2"
				shift
			else
                printf $redbg'ERROR: "--mysqlhost" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
		-n|--name)
			if [ -n "$2" ]; then
				ncname="$2"
				shift
			else
                printf $redbg'ERROR: "--name" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
		-u|--url)
			if [ -n "$2" ]; then
				url1="$2"
				shift
			else
                printf $redbg'ERROR: "--url" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
		-d|--directory)
			if [ -n "$2" ]; then
				html="$2"
				shift
			else
                printf $redbg'ERROR: "--directory" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
		-f|--folder)
				folder="$2"
				shift
            ;;
		-s|--smtp)
			if [ -n "$2" ]; then
				smtp="$2"
				shift
			else
                printf $redbg'ERROR: "--smtp" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
		-a|--apps)
			if [ -n "$2" ]; then
				appsinstall="$2"
				shift
			else
                printf $redbg'ERROR: "--apps" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf $redbg'Invalid option: %s' "$1" >&2
			printf $reset"\n"
			stty echo
			exit 0
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

header=' _____ _      _         _    _           _
|  __ (_)    | |       | |  | |         | |
| |__) |  ___| |_ ___  | |__| | ___  ___| |_
|  ___/ |/ _ \ __/ __| |  __  |/ _ \/ __| __|	+-+-+-+-+
| |   | |  __/ |_\__ \ | |  | | (_) \__ \ |_ 	| v 1.7 |
|_|   |_|\___|\__|___/ |_|  |_|\___/|___/\__|	+-+-+-+-+'

# Set color for Status
check_ok=$green"   OK  "$reset
check_miss=$redbg"MISSING"$reset

# Define latest Nextcloud version
ncrepo="https://download.nextcloud.com/server/releases"

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, type: sudo -i"; stty echo; exit 1; }

##########################################################################################

###################################
######   BEFORE SETUP START   #####
###################################

printf $green"$header"$reset
echo ""
echo ""

printf "Checking minimal system requirements...\n"
echo ""
sleep 2

# Ensure the OS is compatible with the installer
if [ -f /etc/centos-release ]; then
    os="CentOs"
    verfull=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
    ver=${verfull:0:1}
elif [ -f /etc/lsb-release ]; then
    os=$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')
    ver=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')
elif [ -f /etc/fedora-release ]; then
	os=$(grep -w ID /etc/os-release | sed 's/^.*=//')
	ver=$(grep VERSION_ID /etc/os-release | cut -c 12-)
elif [ -f /etc/os-release ]; then
    os=$(grep -w ID /etc/os-release | sed 's/^.*=//')
    ver=$(grep VERSION_ID /etc/os-release | sed 's/^.*"\(.*\)"/\1/')
 else
    os=$(uname -s)
    ver=$(uname -r)
fi
	arch=$(uname -m)

printf $yellow"Detected : $os $ver $arch\n"$reset
echo ""
sleep 1

if [[ "$os" = "CentOs" && ("$ver" = "6" || "$ver" = "7" ) ||
      "$os" = "Ubuntu" && ("$ver" = "12.04" || "$ver" = "14.04" || "$ver" = "16.04"  ) ||
      "$os" = "debian" && ("$ver" = "7" || "$ver" = "8" ) ||
	  "$os" = "fedora" && ("$ver" = "23" || "$ver" = "25") ]]; then
	printf $green"Very Good! Your OS is compatible.\n"$reset
	echo ""
	sleep 1
else
    printf $red"Unfortunately, this OS is not supported by Piet's Host Install-script for Nextcloud.\n"$reset
    echo ""
	sleep 2
	stty echo
	exit 1
fi
sleep 1

printf $yellow"Installing dependencies...(may take some time)\n"$reset

{
if [[ "$os" = "Ubuntu" && ("$ver" = "12.04" || "$ver" = "14.04" || "$ver" = "16.04"  ) ]]; then
htuser='www-data'
htgroup='www-data'
dpkg -l | grep -qw pv || apt-get install pv -y
dpkg -l | grep -qw bzip2 || apt-get install bzip2 -y
dpkg -l | grep -qw rsync || apt-get install rsync -y
dpkg -l | grep -qw bc || apt-get install bc -y
dpkg -l | grep -qw xmlstarlet || apt-get install xmlstarlet -y
	#Check for Plesk installation
	if dpkg -l | grep -q psa; then
		dbruser='admin'
	else
		dbruser='root'
	fi
elif [[ "$os" = "debian" && ("$ver" = "7" || "$ver" = "8" ) ]]; then
htuser='www-data'
htgroup='www-data'
dpkg -l | grep -qw pv || apt-get install pv -y
dpkg -l | grep -qw bzip2 || apt-get install bzip2 -y
dpkg -l | grep -qw rsync || apt-get install rsync -y
dpkg -l | grep -qw bc || apt-get install bc -y
dpkg -l | grep -qw xmlstarlet || apt-get install xmlstarlet -y
	#Check for Plesk installation
	if dpkg -l | grep -q psa; then
		dbruser='admin'
	else
		dbruser='root'
	fi
elif [[ "$os" = "CentOs" && ("$ver" = "6" || "$ver" = "7" ) ]]; then
htuser='apache'
htgroup='apache'
rpm -qa | grep -qw pv || yum install pv -y
rpm -qa | grep -qw bc || yum install bc -y
rpm -qa | grep -qw bzip2 || yum install bzip2 -y
rpm -qa | grep -qw rsync || yum install rsync -y
rpm -qa | grep -qw php-process || yum install php-process -y
rpm -qa | grep -qw xmlstarlet || yum install xmlstarlet -y
	#Check for Plesk installation
	if rpm -qa | grep -q psa; then
		dbruser='admin'
	else
		dbruser='root'
	fi
elif [[ "$os" = "fedora" && ("$ver" = "23" || "$ver" = "25") ]]; then
htuser='apache'
htgroup='apache'
rpm -qa | grep -qw pv || dnf install pv -y
rpm -qa | grep -qw bc || dnf install bc -y
rpm -qa | grep -qw bzip2 || dnf install bzip2 -y
rpm -qa | grep -qw rsync || dnf install rsync -y
rpm -qa | grep -qw php-process || dnf install php-process -y
rpm -qa | grep -qw xmlstarlet || dnf install xmlstarlet -y
	#Check for Plesk installation
	if rpm -qa | grep -q psa; then
		dbruser='admin'
	else
		dbruser='root'
	fi
fi
} &> /dev/null

#################################
######   BEFORE SETUP END   #####
#################################

# Check Status on startup
folderstat="$check_ok"
function check(){
[  -z "$url1" ] && domainstat="$check_miss" || domainstat="$check_ok"
[  -z "$ncname" ] && namestat="$check_miss" || namestat="$check_ok"
[  -z "$html" ] && htmlstat="$check_miss" || htmlstat="$check_ok"
[  -z "$dbtype" ] && dbtypestat="$check_miss" || dbtypestat="$check_ok"
[  -z "$dbhost" ] && dbhoststat="$check_miss" || dbhoststat="$check_ok"
[  -z "$email" ] && emailstat="$check_miss" || emailstat="$check_ok"
[  -z "$smtpauth" ] && smauthstat="$check_miss" || smauthstat="$check_ok"
[  -z "$smtpauthreq" ] && smauthreqstat="$check_miss" || smauthreqstat="$check_ok"
[  -z "$smtphost" ] && smhoststat="$check_miss" || smhoststat="$check_ok"
[  -z "$smtpport" ] && smportstat="$check_miss" || smportstat="$check_ok"
[  -z "$smtpname" ] && smnamestat="$check_miss" || smnamestat="$check_ok"
[  -z "$smtppwd" ] && smpwdstat="$check_miss" || smpwdstat="$check_ok"
[  -z "$smtpsec" ] && smsecstat="$check_miss" || smsecstat="$check_ok"
[  -z "$htuser" ] && htusrstat="$check_miss" || htusrstat="$check_ok"
[  -z "$htgroup" ] && htgrpstat="$check_miss" || htgrpstat="$check_ok"
[  -z "$rootuser" ] && rootusrstat="$check_miss" || rootusrstat="$check_ok"
[  -z "$adminuser" ] && adusrstat="$check_miss" || adusrstat="$check_ok"
[  -z "$dbruser" ] && dbusrstat="$check_miss" || dbusrstat="$check_ok"
[  -z "$database_root" ] && dbrootstat="$check_miss" || dbrootstat="$check_ok"
[  -z "$smtpdomain" ] && smtpdomainstat="$check_miss" || smtpdomainstat="$check_ok"
[  -z "$displayname" ] && dpnamestat="$check_miss" || dpnamestat="$check_ok"
[  -z "$rlchannel" ] && rlchanstat="$check_miss" || rlchanstat="$check_ok"
[  -z "$memcache" ] && memstat="$check_miss" || memstat="$check_ok"
[  -z "$maintenance" ] && maintstat="$check_miss" || maintstat="$check_ok"
[  -z "$singleuser" ] && singlestat="$check_miss" || singlestat="$check_ok"
[  -z "$skeleton" ] && skeletonstat="$check_miss" || skeletonstat="$check_ok"
[  -z "$default_language" ] && langstat="$check_miss" || langstat="$check_ok"
[  -z "$enable_avatars" ] && enavastat="$check_miss" || enavastat="$check_ok"
[  -z "$rewritebase" ] && rewritestat="$check_miss" || rewritestat="$check_ok"
}

function checkapps(){
[  -z "$contactsinstall" ] && contactsstat="$check_miss" || contactsstat="$check_ok"
[  -z "$calendarinstall" ] && calendarstat="$check_miss" || calendarstat="$check_ok"
[  -z "$mailinstall" ] && mailstat="$check_miss" || mailstat="$check_ok"
[  -z "$notesinstall" ] && notesstat="$check_miss" || notesstat="$check_ok"
[  -z "$tasksinstall" ] && tasksstat="$check_miss" || tasksstat="$check_ok"
[  -z "$galleryinstall" ] && gallerystat="$check_miss" || gallerystat="$check_ok"
[  -z "$impinstall" ] && impstat="$check_miss" || impstat="$check_ok"
}

function printhead {
clear
printf $green"$header"$reset
echo ""
}

# autoinput on keypress
readOne () {
	stty echo
    local oldstty
    oldstty=$(stty -g)
    stty -icanon -echo min 1 time 0
    dd bs=1 count=1 2>/dev/null
    stty "$oldstty"
	stty -echo
}

function contactsinstall {
		# Download and install Contacts
		if [ -d $ncpath/apps/contacts ]
		then
			sleep 1
		else
			wget -q $contacs_repo/v$contacs/$contacs_file -P $ncpath/apps
			tar -zxf $ncpath/apps/$contacs_file -C $ncpath/apps
			cd $ncpath/apps
			rm $contacs_file
		fi

		# Enable Contacts
		if [ -d $ncpath/apps/contacts ]
		then
			sudo -u ${htuser} php $ncpath/occ app:enable contacts
		fi
		}

function calendarinstall {
		# Download and install Calendar
		if [ -d $ncpath/apps/calendar ]
		then
			sleep 1
		else
			wget -q $calendar_repo/v$calendar/$calendar_file -P $ncpath/apps
			tar -zxf $ncpath/apps/$calendar_file -C $ncpath/apps
			cd $ncpath/apps
			rm $calendar_file
		fi

		# Enable Calendar
		if [ -d $ncpath/apps/calendar ]
		then
			sudo -u ${htuser} php $ncpath/occ app:enable calendar
		fi
		}

function mailinstall {
		# Download and install Mail
		if [ -d $ncpath/apps/mail ]
		then
			sleep 1
		else
			wget -q $mail_repo/v$mail/$mail_file -P $ncpath/apps
			tar -zxf $ncpath/apps/$mail_file -C $ncpath/apps
			cd $ncpath/apps
			rm $mail_file
		fi

		# Enable Mail
		if [ -d $ncpath/apps/mail ]
		then
			sudo -u ${htuser} php $ncpath/occ app:enable mail
		fi
		}

function notesinstall {
		# Download and install Notes
		if [ -d $ncpath/apps/notes ]
		then
			sleep 1
		else
			wget -q $notes_repo/v$notes/$notes_file -P $ncpath/apps
			tar -zxf $ncpath/apps/$notes_file -C $ncpath/apps
			cd $ncpath/apps
			rm $notes_file
		fi

		# Enable Notes
		if [ -d $ncpath/apps/notes ]
		then
			sudo -u ${htuser} php $ncpath/occ app:enable notes
		fi
		}

function tasksinstall {
		# Download and install Tasks
		if [ -d $ncpath/apps/tasks ]
		then
			sleep 1
		else
			wget -q $tasks_repo/v$tasks/$tasks_file -P $ncpath/apps
			tar -zxf $ncpath/apps/$tasks_file -C $ncpath/apps
			cd $ncpath/apps
			rm $tasks_file
		fi

		# Enable Tasks
		if [ -d $ncpath/apps/tasks ]
		then
			sudo -u ${htuser} php $ncpath/occ app:enable tasks
		fi
		}

function galleryinstall {
		# Download and install Gallery
		if [ -d $ncpath/apps/gallery ]
		then
			sleep 1
		else
			wget -q $gallery_repo/v$gallery/$gallery_file -P $ncpath/apps
			tar -zxf $ncpath/apps/$gallery_file -C $ncpath/apps
			cd $ncpath/apps
			rm $gallery_file
		fi

		# Enable Gallery
		if [ -d $ncpath/apps/gallery ]
		then
			sudo -u ${htuser} php $ncpath/occ app:enable gallery
		fi
		}

function impersonateinstall {
		# Download and install impersonate
		if [ -d $ncpath/apps/impersonate ]
		then
			sleep 1
		else
			wget -q $impersonate_repo/$impersonate_file -P $ncpath/apps
			tar -zxf $ncpath/apps/$impersonate_file
			mv $impersonate_folder $impersonate_new
			mv $impersonate_new $ncpath/apps
			cd $ncpath/apps
			rm -f $impersonate_file
		fi

		# Enable impersonate
		if [ -d $ncpath/apps/impersonate ]
		then
			# Set minimum-version to 10 since 12 isn't released yet
			xmlstarlet edit -L -u "/info/dependencies/nextcloud[@min-version='12'] [@max-version='12']/@min-version" -v 10 $ncpath/apps/impersonate/appinfo/info.xml
			sudo -u ${htuser} php $ncpath/occ app:enable impersonate
		fi
		}		

function progress () {
    s=0.75;
    f=0.2;
    echo -ne "\r\n";
    while true; do
           sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [             ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [>            ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [-->          ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [--->         ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [---->        ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [----->       ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [------>      ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [------->     ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [-------->    ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [--------->   ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [---------->  ] working: ${s} secs." \
        && sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [-----------> ] working: ${s} secs.";
           sleep $f && s=`echo ${s} + ${f} | bc` && echo -ne "\r [------------>] working: ${s} secs.";
    done;
}

function smtpsetup(){
clear
while true; do
  printhead
echo ""
stty echo
  echo "--------------------------------------------------------------------------"
  echo "                    Setup SMTP"
  echo "------+------------+-----------------+------------------------------------"
  echo "  Nr. |   Status   |     description |    value"
  echo "------+------------+-----------------+------------------------------------"
  printf "  1   |  $smauthstat   |      Auth-Type: | "$smtpauth"\n"
  printf "  2   |  $smhoststat   |      SMTP-Host: | "$smtphost"\n"
  printf "  3   |  $smportstat   |           Port: | "$smtpport"\n"
  printf "  4   |  $smnamestat   |    Sender Name: | "$smtpname"\n"
  printf "  5   |  $smpwdstat   |  SMTP-Password: | "$smtppwd"\n"
  printf "  6   |  $smsecstat   |    SMTP-Secure: | "$smtpsec"\n"
  printf "  7   |  $smauthreqstat   | Auth required?: | "$smtpauthreq"\n"
  printf "  8   |  $smtpdomainstat   |    SMTP Domain: | "$smtpdomain"\n"
  echo "------+------------+-----------------+------------------------------------"
  printf "Type [1-8] to change value or ${cyan}[s]${reset} to save and go to next page\n"
  printf "${red}[q]${reset} Quit\n"
  echo -en "Enter [1-8], [s] or [q]: ";key2=$(readOne)

  if [ "$key2" = "1" ]; then
  echo ""
  stty echo
  	echo -n "Enter Auth-Type (LOGIN, PLAIN, etc): "
	read smtpauth
    [  -z "$smtpauth" ] && smauthstat="$check_miss" || smauthstat="$check_ok"

  elif [ "$key2" = "2" ]; then
  echo ""
  stty echo
	echo -n "Enter SMTP-Host (e.g. yourdomain.com): "
	read smtphost
	[  -z "$smtphost" ] && smhoststat="$check_miss" || smhoststat="$check_ok"

  elif [ "$key2" = "3" ]; then
  echo ""
  stty echo
	echo -n "Enter SMTP-Port (default :587): "
	read smtpport

	# Check for correct input
	while ! [[ "$smtpport" =~ ^[0-9]+$ ]]; do
		printf $redbg"Wrong input format. Only numbers are supported...: "$reset
		read smtpport
	done
	[  -z "$smtpport" ] && smportstat="$check_miss" || smportstat="$check_ok"

  elif [ "$key2" = "4" ]; then
  echo ""
  stty echo
	echo -n "Enter SMTP-Sendername (e.g. admin, info, etc): "
	read smtpname
	[  -z "$smtpname" ] && smnamestat="$check_miss" || smnamestat="$check_ok"

  elif [ "$key2" = "5" ]; then
  echo ""
  stty echo
	echo -n "Enter SMTP-password: "
	read smtppwd
	[  -z "$smtppwd" ] && smpwdstat="$check_miss" || smpwdstat="$check_ok"

  elif [ "$key2" = "6" ]; then
  echo ""
  stty echo
	echo -n "Enter SMTP-Security (tls, ssl, none): "
	read smtpsec

	# Check for correct input
	while ! [ "$smtpsec" = "tls" ] || [ "$smtpsec" = "ssl" ] || [ "$smtpsec" = "none" ]; do
		printf $redbg"Wrong input format. Type ssl, tls or none...: "$reset
		read smtpsec
	done
	[  -z "$smtpsec" ] && smsecstat="$check_miss" || smsecstat="$check_ok"

  elif [ "$key2" = "7" ]; then
  if [ "$smtpauthreq" = "0" ]; then
		smtpauthreq='1'
		smauthreqstat="$check_ok"
		printf $green"SMTP-Authentification enabled\n"$reset
		sleep 1
	elif [ "$smtpauthreq" = "1" ]; then
		smtpauthreq='0'
		smauthreqstat="$check_ok"
		printf $red"SMTP-Authentification disabled\n"$reset
		sleep 1
	fi

  elif [ "$key2" = "8" ]; then
  echo ""
  stty echo
	echo -n "Set SMTP sender Domain (e.g. yourdomain.com): "
	read smtpdomain
	[  -z "$smtpdomain" ] && smtpdomainstat="$check_miss" || smtpdomainstat="$check_ok"


  elif [ "$key2" = "s" ]; then
  stty echo
        if [ -z "$smtpauth" ] || [ -z "$smtphost" ] || [ -z "$smtpport" ] || [ -z "$smtpname" ] || [ -z "$smtppwd" ] || [ -z "$smtpsec" ] || [ -z "$smtpauthreq" ] || [ -z "$smtpdomain" ]; then
        	printf $redbg"One or more variables are undefined. Aborting..."$reset
        	sleep 3
        	continue
        else
			echo ""
        	echo "-----------------------------"
        break
        fi
  elif [ "$key2" = "q" ]; then
  echo ""
  stty echo
    exit
  fi
done
}

function installapps(){
# Apps
contactsinstall='true'
calendarinstall='true'
mailinstall='false'
notesinstall='false'
tasksinstall='false'
galleryinstall='false'
impinstall='false'

checkapps

clear
while true; do
  printhead
echo ""
stty echo
  echo "--------------------------------------------------------------------"
  echo "                    Setup Apps"
  echo "------+------------+----------------+-------------------------------"
  echo "  Nr. |   Status   |            app |    value"
  echo "------+------------+----------------+-------------------------------"
  printf "  1   |  $contactsstat   |      contacts: |     "$contactsinstall"\n"
  printf "  2   |  $calendarstat   |      calendar: |     "$calendarinstall"\n"
  printf "  3   |  $mailstat   |          mail: |     "$mailinstall"\n"
  printf "  4   |  $notesstat   |         notes: |     "$notesinstall"\n"
  printf "  5   |  $tasksstat   |         tasks: |     "$tasksinstall"\n"
  printf "  6   |  $gallerystat   |       gallery: |     "$galleryinstall"\n"
  printf "  7   |  $impstat   |   impersonate: |     "$impinstall"\n"
  echo "------+------------+----------------+-------------------------------"
  printf "Type [1-7] to change value or ${cyan}[s]${reset} to save and go to next page\n"
  printf "${red}[q]${reset} Quit\n"
  echo -en "Enter [1-7], [s] or [q]: ";key5=$(readOne)

if [ "$key5" = "1" ]; then
	if [ "$contactsinstall" = "true" ]; then
		contactsinstall='false'
		contactsstat="$check_ok"
		printf $red"contacts installation turned off\n"$reset
		sleep 1
	elif [ "$contactsinstall" = "false" ]; then
		contactsinstall='true'
		contactsstat="$check_ok"
		printf $green"contacs installation turned on\n"$reset
		sleep 1
	fi

  elif [ "$key5" = "2" ]; then
	if [ "$calendarinstall" = "true" ]; then
		calendarinstall='false'
		calendarstat="$check_ok"
		printf $red"calendar installation turned off\n"$reset
		sleep 1
	elif [ "$calendarinstall" = "false" ]; then
		calendarinstall='true'
		calendarstat="$check_ok"
		printf $green"calendar installation turned on\n"$reset
		sleep 1
	fi

  elif [ "$key5" = "3" ]; then
	if [ "$mailinstall" = "true" ]; then
		mailinstall='false'
		mailstat="$check_ok"
		printf $red"mail installation turned off\n"$reset
		sleep 1
	elif [ "$mailinstall" = "false" ]; then
		mailinstall='true'
		mailstat="$check_ok"
		printf $green"mail installation turned on\n"$reset
		sleep 1
	fi

  elif [ "$key5" = "4" ]; then
	if [ "$notesinstall" = "true" ]; then
		notesinstall='false'
		notesstat="$check_ok"
		printf $red"notes installation turned off\n"$reset
		sleep 1
	elif [ "$notesinstall" = "false" ]; then
		notesinstall='true'
		notesstat="$check_ok"
		printf $green"notes installation turned on\n"$reset
		sleep 1
	fi

  elif [ "$key5" = "5" ]; then
	if [ "$tasksinstall" = "true" ]; then
		tasksinstall='false'
		tasksstat="$check_ok"
		printf $red"tasks installation turned off\n"$reset
		sleep 1
	elif [ "$tasksinstall" = "false" ]; then
		tasksinstall='true'
		tasksstat="$check_ok"
		printf $green"tasks installation turned on\n"$reset
		sleep 1
	fi

  elif [ "$key5" = "6" ]; then
	if [ "$galleryinstall" = "true" ]; then
		galleryinstall='false'
		gallerystat="$check_ok"
		printf $red"gallery installation turned off\n"$reset
		sleep 1
	elif [ "$galleryinstall" = "false" ]; then
		galleryinstall='true'
		gallerystat="$check_ok"
		printf $green"gallery installation turned on\n"$reset
		sleep 1
	fi

  elif [ "$key5" = "7" ]; then
	if [ "$impinstall" = "true" ]; then
		impinstall='false'
		impstat="$check_ok"
		printf $red"impersonate installation turned off\n"$reset
		sleep 1
	elif [ "$impinstall" = "false" ]; then
		impinstall='true'
		impstat="$check_ok"
		printf $green"impersonate installation turned on\n"$reset
		sleep 1
	fi

	elif [ "$key5" = "s" ]; then
	stty echo
        if [ -z "$contactsinstall" ]; then
        	printf $redbg"One or more variables are undefined. Aborting..."$reset
        	sleep 3
        	continue
        else
        	echo "-----------------------------"
        break
        fi
  elif [ "$key5" = "q" ]; then
  echo ""
  stty echo
    exit
  fi
done
}
###############
##  NC APPS  ##
###############

# Contacs
contacs=$(curl -s https://api.github.com/repos/nextcloud/contacts/releases/latest | grep "tag_name" | cut -d\" -f4 | sed -e "s|v||g")
contacs_file=contacts.tar.gz
contacs_repo=https://github.com/nextcloud/contacts/releases/download
# Calendar
calendar=$(curl -s https://api.github.com/repos/nextcloud/calendar/releases/latest | grep "tag_name" | cut -d\" -f4 | sed -e "s|v||g")
calendar_file=calendar.tar.gz
calendar_repo=https://github.com/nextcloud/calendar/releases/download
# Mail
mail=$(curl -s https://api.github.com/repos/nextcloud/mail/releases/latest | grep "tag_name" | cut -d\" -f4 | sed -e "s|v||g")
mail_file=mail.tar.gz
mail_repo=https://github.com/nextcloud/mail/releases/download
# Tasks
tasks=$(curl -s https://api.github.com/repos/nextcloud/tasks/releases/latest | grep "tag_name" | cut -d\" -f4 | sed -e "s|v||g")
tasks_file=tasks.tar.gz
tasks_repo=https://github.com/nextcloud/tasks/releases/download
# Gallery
gallery=$(curl -s https://api.github.com/repos/nextcloud/gallery/releases/latest | grep "tag_name" | cut -d\" -f4 | sed -e "s|v||g")
gallery_file=gallery.tar.gz
gallery_repo=https://github.com/nextcloud/gallery/releases/download
# Notes
notes=$(curl -s https://api.github.com/repos/nextcloud/notes/releases/latest | grep "tag_name" | cut -d\" -f4 | sed -e "s|v||g")
notes_file=notes.tar.gz
notes_repo=https://github.com/nextcloud/notes/releases/download
# impersonate
impersonate_file=v1.0.1.tar.gz
impersonate_folder="./impersonate-1.0.1"
impersonate_new="impersonate"
impersonate_repo=https://github.com/nextcloud/impersonate/archive/
#################################
######   INITIALIZATION    ######
#################################

# enable user input
stty echo

# clear user input
read -t 1 -n 100 discard

printhead
echo ""

  echo "--------------------------------------------------------"
  echo "    Welcome to Piet's Host Nextcloud Install-Script     "
  echo "------+------------------------------------------+------"
  ########    |------------------------------------------|"$var
  echo "      |    This Script will install Nextcloud    |"
  echo "      |    for you. To make it work, you have    |"
  echo "      |      to enter some variables on the      |"
  echo "      |             following pages.             |"
  echo "      |    Please read the documentation at      |"
  echo "      |     github for further information,      |"
  echo "      |    what syntax is required to make the   |"
  echo "      |       	      script work.               |"
  echo "      |                                          |"
  echo "      |     Note: you can not go back within     |"
  echo "      |    this script! please read carefully    |"
  echo "      |              what is required.           |"
  echo "      |                                          |"
  printf "      |  $yellow Database-Name, Database-password and  $reset |\n"
  printf "      |    $yellow Admin-password will be generated    $reset |\n"
  printf "      |              $yellow automatically.            $reset |\n"
  echo "------+------------------------------------------+------"
  echo "      |                                          |"
  echo "------+------------------------------------------+------"

read -n1 -r -p "      |   Press any key to continue...           | " key

if [ "$key" = '' ]; then
	return
fi
echo ""
stty -echo
printhead
echo ""

#################################
######   INITIALIZATION    ######
#################################

##########################################################################################

###################################
######   Setup Page 1 Start   #####
###################################

regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
regexmail="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
regexhttps='(https|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
stty echo

check
clear
while true; do
  printhead
echo ""

  echo "--------------------------------------------------------------------------"
  echo "                    Setup			Page 1/3"
  echo "------+------------+-----------------+------------------------------------"
  echo "  Nr. |   Status   |     description |    value"
  echo "------+------------+-----------------+------------------------------------"
  ###########    |xx-----------xxx|xxxxxxxxxXXXXXX:x|x"$var
  printf "  1   |  $domainstat   |         Domain: | "$url1"\n"
  printf "  2   |  $namestat   |           name: | "$ncname"\n"
  printf "  3   |  $htmlstat   |      directory: | "$html"\n"
  printf "  4   |  $folderstat   |         folder: | "$folder"\n"
  echo ""
  printf "  5   |  $dbtypestat   |        DB-Type: | "$dbtype"\n"
  printf "  6   |  $dbhoststat   |        DB-Host: | "$dbhost"\n"
  echo "------+------------+-----------------+------------------------------------"
  printf "Type [1-6] to change value or ${cyan}[s]${reset} to save and go to next page\n"
  printf "${red}[q]${reset} Quit\n"
  echo -n "Enter [1-6], [s] or [q]: ";key1=$(readOne)

  if [ "$key1" = "1" ]; then
  echo ""
  stty echo
  	echo -n "Enter url (with http:// or https://): "
	read url1

	# Check for correct input
	if [[ $url1 =~ $regex ]]; then
		[  -z "$url1" ] && domainstat="$check_miss" || domainstat="$check_ok"
		if [[ $url1 =~ $regexhttps ]]; then
			printf $redbg"Make sure you have a valid SSL-Certificate or Nextcloud won't work as expected\n"$reset
			sleep 4
			read -n1 -r -p " Press any key to continue... " key
			if [ "$key" = '' ]; then
				return
			fi
		fi
	else
		printf $redbg"Wrong input format. Enter a valid URL..."$reset
		url1="http://example.com"
        sleep 3
        continue
	fi

  elif [ "$key1" = "2" ]; then
  echo ""
  stty echo
	echo -n "Enter name: "
	read ncname
	[  -z "$ncname" ] && namestat="$check_miss" || namestat="$check_ok"

  elif [ "$key1" = "3" ]; then
  echo ""
  stty echo
	echo -n "Enter html-directory (e.g. /var/www/html): "
	read html

	# Check for correct input
	while ! [[ -d $html ]]; do
	printf $redbg"Wrong input format or choosen directory does not exist... Enter html-directory: "$reset
	read html
    done
	[ -z "$html" ] && htmlstat="$check_miss" || htmlstat="$check_ok"

  elif [ "$key1" = "4" ]; then
  echo ""
  stty echo
	echo -n "Enter folder name (Leave empty, if you want to install to root directory): "
	read folder
	[ "$folder" ] && folderstat="$check_ok"

  elif [ "$key1" = "5" ]; then
  echo ""
  stty echo
	echo -n "Enter Database-Type (e.g. mysql, sqlite, etc.): "
	read dbtype
	[  -z "$dbtype" ] && dbtypestat="$check_miss" || dbtypestat="$check_ok"

  elif [ "$key1" = "6" ]; then
  echo ""
  stty echo
	echo -n "Enter Database-Host (e.g. localhost): "
	read dbhost
	[ -z "$dbhost" ] && dbhoststat="$check_miss" || dbhoststat="$check_ok"

  elif [ "$key1" = "s" ]; then
  stty echo
        if [ -z "$url1" ] || [ -z "$ncname" ] || [ -z "$html" ] || [ -z "$dbtype" ] || [ -z "$dbhost" ]; then
        	printf $redbg"One or more variables are undefined. Aborting..."$reset
        	sleep 3
        	continue
        else
			echo ""
        	echo "-----------------------------"
        break
        fi
  elif [ "$key1" = "q" ]; then
  echo ""
  stty echo
    exit
  fi
done
stty -echo
standardpath=$html/nextcloud
ncpath=$html/$folder
sleep 1
#################################
######   Setup Page 1 End   #####
#################################

# Check if Nextcloud is already installed installed.

if [ -f "$ncpath/occ" ]; then
	chmod +x $ncpath/occ
	CURRENTVERSION=$(sudo -u $htuser php $ncpath/occ status | grep "versionstring" | awk '{print $3}')
	echo ""
    printf $redbg"Nextcloud is already installed...\n"$reset
	echo ""
	echo "If your version isn't up to date make use of the Piet's Host ncupdate-script."
	echo ""
	sleep 2
	stty echo
    exit 0
else
	echo ""
    printf $green"No Nextcloud installation found! Installing continues...\n"$reset
	echo ""
	sleep 2
fi
stty echo

###################################
######   Setup Page 2 Start   #####
###################################

clear
while true; do
  printhead
echo ""
stty echo
  echo "--------------------------------------------------------------------------"
  echo "                    Setup			Page 2/3"
  echo "------+------------+------------------+------------------------------------"
  echo "  Nr. |   Status   |      description |    value"
  echo "------+------------+------------------+------------------------------------"
  printf "  1   |  $emailstat   |          E-Mail: | "$email"\n"
  printf "  2   |  $adusrstat   |  Admin Username: | "$adminuser"\n"
  echo ""
   printf "  3   |  $dbusrstat   |     DB Username: | "$dbruser"\n"
  echo -e "  4   |  $dbrootstat   |Database Root-PW: | "$database_root
  echo ""
  printf "  5   |  $htusrstat   |        WWW User: | "$htuser"\n"
  printf "  6   |  $htgrpstat   |       WWW Group: | "$htgroup"\n"
  printf "  7   |  $rootusrstat   |       root user: | "$rootuser"\n"
  echo "------+------------+------------------+------------------------------------"
  printf "Type [1-7] to change value or ${cyan}[s]${reset} to save and go to next page\n"
  printf "${red}[q]${reset} Quit\n"
  echo -en "Enter [1-7], [s] or [q]: ";key3=$(readOne)

  if [ "$key3" = "1" ]; then
  echo ""
  stty echo
  	echo -n "Enter your E-mail: "
	read email

	# Check for correct input
	if [[ $email =~ $regexmail ]]; then
		[  -z "$email" ] && emailstat="$check_miss" || emailstat="$check_ok"
	else
		printf $redbg"Wrong input format. Enter a valid email address..."$reset
		email='mail@example.com'
        sleep 3
        continue
	fi

  elif [ "$key3" = "2" ]; then
  echo ""
  stty echo
	echo -n "Please enter desired admin username for Nextcloud: "
	read adminuser

	# Make security advise in case of root or admin as username
	shopt -s nocasematch
	if [[ "$adminuser" = "root" ]] || [[ "$adminuser" = "admin" ]]; then
		[  -z "$adminuser" ] && adusrstat="$check_miss" || adusrstat="$check_ok"
		printf $redbg"Please don't use this username for security reasons. You should choose a unique username :) \n"$reset
		read -n1 -r -p " Press any key to continue... " key
		if [ "$key" = '' ]; then
			return
		fi
	else
		[  -z "$adminuser" ] && adusrstat="$check_miss" || adusrstat="$check_ok"
	fi
	shopt -u nocasematch

  elif [ "$key3" = "3" ]; then
  echo ""
  stty echo
	echo -n "Please enter Database Root username: "
	read dbruser
	[  -z "$dbruser" ] && dbusrstat="$check_miss" || dbusrstat="$check_ok"

  elif [ "$key3" = "4" ]; then
  echo ""
  stty echo
	echo -n "Please enter password for database root account (won't be stored): "
	read database_root

	# function check MySQL Login
	function mysqlcheck () {
	if [[ "dbhost" = "localhost" ]]; then
	mysql -u $dbruser -p$database_root  -e ";"
	else
	mysql -u $dbruser -p$database_root -h $dbhost -e ";"
	fi
	} &> /dev/null

	while ! mysqlcheck ; do
	printf $redbg"Wrong password! Please enter the MySQL root password!: "$reset
       read database_root
	done
	[  -z "$database_root" ] && dbrootstat="$check_miss" || dbrootstat="$check_ok"

  elif [ "$key3" = "5" ]; then
  echo ""
  stty echo
	echo -n "Enter WWW-User (e.g. apache, apache2, etc.): "
	read htuser
	while ! id "$htuser" >/dev/null 2>&1; do
		printf $redbg"This user does not exist! Enter WWW-User: "$reset
		read htuser
	done
    [  -z "$rootuser" ] && rootusrstat="$check_miss" || rootusrstat="$check_ok"

  elif [ "$key3" = "6" ]; then
  echo ""
  stty echo
	echo -n "Enter WWW-Group (e.g. apache, www-data, etc.): "
	read htgroup

   while ! grep -q $htgroup /etc/group >/dev/null 2>&1; do
    printf $redbg"This user does not exist! Enter WWW-Group: "$reset
		read htgroup
	done
    [  -z "$htgroup" ] && htgrpstat="$check_miss" || htgrpstat="$check_ok"

  elif [ "$key3" = "7" ]; then
  echo ""
  stty echo
	echo -n "Enter root user (usually: root): "
	read rootuser
	while ! id "$rootuser" >/dev/null 2>&1; do
		printf $redbg"This user does not exist! Enter root user: "$reset
		read rootuser
	done
    [  -z "$rootuser" ] && rootusrstat="$check_miss" || rootusrstat="$check_ok"

  elif [ "$key3" = "s" ]; then
  stty echo
        if [ -z "$email" ] || [ -z "$htuser" ] || [ -z "$htgroup" ] || [ -z "$rootuser" ] || [ -z "$dbruser" ] || [ -z "$adminuser" ] || [ -z "$database_root" ]; then
        	printf $redbg"One or more variables are undefined. Aborting..."$reset
        	sleep 3
        	continue
        else
			echo ""
        	echo "-----------------------------"
        break
        fi
  elif [ "$key3" = "q" ]; then
  echo ""
  stty echo
    exit
  fi
done
sleep 1
#################################
######   Setup Page 2 End   #####
#################################

###################################
######   Setup Page 3 Start   #####
###################################

clear
while true; do
  printhead
echo ""
stty echo
  echo "--------------------------------------------------------------------------"
  echo "                    Setup			Page 3/3"
  echo "------+------------+-------------------------------+-----------------------"
  echo "  Nr. |   Status   |                   description |    value"
  echo "------+------------+-------------------------------+-----------------------"
  printf "  1   |  $dpnamestat   | allow change of display name: | "$displayname"\n"
  printf "  2   |  $rlchanstat   |              Release Channel: | "$rlchannel"\n"
  printf "  3   |  $memstat   |                     Memcache: | "$memcache"\n"
  printf "  4   |  $maintstat   |             maintenance mode: | "$maintenance"\n"
  printf "  5   |  $singlestat   |              singleuser mode: | "$singleuser"\n"
  printf "  6   |  $skeletonstat   |    custom skeleton directory: | "$skeleton"\n"
  printf "  7   |  $skeletonstat   |             default language: | "$default_language"\n"
  printf "  8   |  $skeletonstat   |               enable avatars: | "$enable_avatars"\n"
  printf "  9   |  $skeletonstat   |                  pretty URLs: | "$rewritebase"\n"
  echo "------+------------+-------------------------------+---------------------------------"
  printf "Type [1-9] to change value or ${cyan}[s]${reset} to save and go to next page\n"
  printf "${red}[q]${reset} Quit\n"
  echo -en "Enter [1-9], [s] or [q]: ";key4=$(readOne)

  if [ "$key4" = "1" ]; then
  if [ "$displayname" = "true" ]; then
		displayname='false'
		dpnamestat="$check_ok"
		printf $red"allow change of display name set to false\n"$reset
		sleep 1
	elif [ "$displayname" = "false" ]; then
		displayname='true'
		dpnamestat="$check_ok"
		printf $green"allow change of display name set to true\n"$reset
		sleep 1
	fi

  elif [ "$key4" = "2" ]; then
  echo ""
  stty echo
	echo -n "The channel that Nextcloud should use to look for updates (daily, beta, stable, production) "
	read rlchannel

	# Check for correct input
	shopt -s nocasematch
	if [[ "$rlchannel" = "daily" ]] || [[ "$rlchannel" = "beta" ]] || [[ "$rlchannel" = "stable" ]] || [[ "$rlchannel" = "production" ]]; then
		[  -z "$rlchannel" ] && rlchanstat="$check_miss" || rlchanstat="$check_ok"
	else
		printf $redbg"Wrong input format. Please type daily, beta, stable or production..."$reset
		rlchannel='stable'
        sleep 3
        continue
	fi
	shopt -u nocasematch

  elif [ "$key4" = "3" ]; then
  echo ""
  stty echo
	echo -n "Do you want to use memcache? (none, APCu): "
	read memcache

	# Check for correct input
	shopt -s nocasematch
	if [[ "$memcache" = "none" ]] || [[ "$memcache" = "APCu" ]]; then
		[  -z "$memcache" ] && memstat="$check_miss" || memstat="$check_ok"
	else
		printf $redbg"Wrong input format. Please type none or APCu..."$reset
		memcache='none'
        sleep 3
        continue
	fi
	shopt -u nocasematch

  elif [ "$key4" = "4" ]; then
  if [ "$maintenance" = "true" ]; then
		maintenance='false'
		maintstat="$check_ok"
		printf $red"maintenance mode set to false\n"$reset
		sleep 1
	elif [ "$maintenance" = "false" ]; then
		maintenance='true'
		maintstat="$check_ok"
		printf $green"maintenance mode set to true\n"$reset
		sleep 1
	fi

  elif [ "$key4" = "5" ]; then
	if [ "$singleuser" = "true" ]; then
		singleuser='false'
		singlestat="$check_ok"
		printf $red"singleuser mode set to false\n"$reset
		sleep 1
	elif [ "$singleuser" = "false" ]; then
		singleuser='true'
		singlestat="$check_ok"
		printf $green"singleuser mode set to true\n"$reset
		sleep 1
	fi

  elif [ "$key4" = "6" ]; then
  echo ""
  stty echo
	echo -n "Enter custom skeleton directory or type none for default: "
	read skeleton

	shopt -s nocasematch
	if [ "$skeleton" = "none" ]; then
		[  -z "$skeleton" ] && skeletonstat="$check_miss" || skeletonstat="$check_ok"
		skeleton='none'
	else
		shopt -u nocasematch
		# Check for correct input
		if [[ -d $skeleton ]]; then
			[  -z "$skeleton" ] && skeletonstat="$check_miss" || skeletonstat="$check_ok"
		else
			printf $redbg"Wrong input format or choosen directory does not exist..."$reset
			skeleton='none'
			sleep 3
			continue
		fi
	fi

	elif [ "$key4" = "7" ]; then
	echo ""
	stty echo
	echo -n "Enter default language (e.g. de, en, fr, etc..): "
	read default_language
	[  -z "$default_language" ] && langstat="$check_miss" || langstat="$check_ok"

	elif [ "$key4" = "8" ]; then
	if [ "$enable_avatars" = "true" ]; then
		enable_avatars='false'
		enavastat="$check_ok"
		printf $red"enable avatars set to false\n"$reset
		sleep 1
	elif [ "$enable_avatars" = "false" ]; then
		enable_avatars='true'
		enavastat="$check_ok"
		printf $green"enable avatars set to true\n"$reset
		sleep 1
	fi

	elif [ "$key4" = "9" ]; then
	if [ "$rewritebase" = "true" ]; then
		rewritebase='false'
		rewritestat="$check_ok"
		printf $red"RewriteBase disabled\n"$reset
		sleep 1
	elif [ "$rewritebase" = "false" ]; then
		rewritebase='true'
		rewritestat="$check_ok"
		printf $green"RewriteBase enabled\n"$reset
		sleep 1
	fi

  elif [ "$key4" = "s" ]; then
  echo ""
  stty echo
        if [ -z "$rlchannel" ] || [ -z "$memcache" ]; then
        	printf $redbg"One or more variables are undefined. Aborting..."$reset
			sleep 3
        	continue
        else
			echo ""
        	echo "-----------------------------"
        break
        fi
  elif [ "$key4" = "q" ]; then
  echo ""
  stty echo
    exit
  fi
done
#################################
######   Setup Page 3 End   #####
#################################

#################################
######   SMTP-Setup Start   #####
#################################

# ask for SMTP-Setup
printhead
if [ "$smtp" == "y" ] || [ "$smtp" == "Y" ]; then
	echo ""
	smtpsetup
elif [ "$smtp" == "n" ] || [ "$smtp" == "N" ]; then
	printhead
	echo ""
	printf "Skipping SMTP Setup..."
	sleep 1
elif [ -z "$smtp" ]; then
	echo ""
	echo -en "Do you want to setup SMTP (y/n)? ";smtp=$(readOne)
	if [ "$smtp" == "y" ] || [ "$smtp" == "Y" ]; then
		smtpsetup
	else
		printhead
		echo ""
		printf "Skipping SMTP Setup..."
		sleep 1
	fi
fi
sleep 1
###############################
######   SMTP-Setup End   #####
###############################

#################################
######   Apps-Setup Start   #####
#################################

# ask for Apps-Setup
printhead
if [ "$appsinstall" == "y" ] || [ "$appsinstall" == "Y" ]; then
	echo ""
	installapps
elif [ "$appsinstall" == "n" ] || [ "$appsinstall" == "N" ]; then
	contactsinstall='false'
	calendarinstall='false'
	mailinstall='false'
	notesinstall='false'
	tasksinstall='false'
	galleryinstall'false'
	impinstall='false'
	printhead
	echo ""
	printf "Skipping Apps Setup..."
	sleep 1

elif [ -z "$appsinstall" ]; then
	echo ""
	echo -en "Do you want to setup additional Apps (y/n)? ";appsinstall=$(readOne)
	if [ "$appsinstall" == "y" ] || [ "$appsinstall" == "Y" ]; then
		installapps
	else
		contactsinstall='false'
		calendarinstall='false'
		mailinstall='false'
		notesinstall='false'
		tasksinstall='false'
		galleryinstall'false'
		impinstall='false'
		printhead
		echo ""
		printf "Skipping Apps Setup..."
		sleep 1
	fi
fi
stty -echo

###############################
######   Apps-Setup End   #####
###############################

printhead
echo ""
# Get latest nextcloud version
if [[ -n "$version" ]]; then
	ncversion=${version}
	echo "Checking Nextcloud v${version} on the download server and if it's possible to download..."
else
	ncversion=$(curl -s -m 900 $ncrepo/ | tac | grep unknown.gif | sed 's/.*"nextcloud-\([^"]*\).zip.sha512".*/\1/;q')
	echo "Checking latest version on the Nextcloud download server and if it's possible to download..."
fi

# Check Nextcloud download
echo ""
wget -q -T 10 -t 2 $ncrepo/nextcloud-$ncversion.tar.bz2 > /dev/null
if [ $? -eq 0 ]; then
    printf $ugreen"SUCCESS!\n"$reset
	sleep 1
	rm -f nextcloud-$ncversion.tar.bz2
else
    printf $lightred"Nextcloud version ${version} doesn't exist.\n"$reset
	echo ""
    printf "Please check available versions here: ${ugreen}${ncrepo}\n"$reset
    echo ""
	stty echo
    exit 1
fi

# Check if variables are set
if [ -z "$html" ] || [ -z "$ncpath" ] || [ -z "$ncname" ] || [ -z "$dbhost" ] || [ -z "$dbtype" ] || [ -z "$htuser" ] || [ -z "$htgroup" ] || [ -z "$rootuser" ] || [ -z "$standardpath" ] || [ -z "$ncrepo" ] || [ -z "$ncversion" ];
then

	echo ""
	printf $redbg"One or more variables are undefined. Aborting...\n"$reset
	echo ""
	sleep 1
	stty echo
	exit 0
else

# Install Warning
echo ""
echo "Performing install in 5 seconds.."
echo ""
printf "  |====>               |   (20%%)\r"
sleep 1
printf "  |=======>            |   (40%%)\r"
sleep 1
printf "  |===========>        |   (60%%)\r"
sleep 1
printf "  |===============>    |   (80%%)\r"
sleep 1
printf "  |===================>|   (100%%)\r"
printf "\n"
fi

####################
##  INSTALLATION  ##
####################

# Download latest Nextcloud-Files
	echo ""
	echo "Downloading $ncrepo/nextcloud-$ncversion.tar.bz2..."
echo ""
wget -q -T 10 -t 2 $ncrepo/nextcloud-$ncversion.tar.bz2 -P $html

# Check if download completed successfully
if [ -f $html/nextcloud-$ncversion.tar.bz2 ]
then
    printf "Download of nextcloud-$ncversion.tar.bz2 ${green}successfull\n"$reset
	echo ""
else
    echo "Oh no! Something went wrong with the download"
	stty echo
	exit 1
fi

# Extract files and move into right folder
printf $yellow"Files are being extracted... \n"$reset
echo ""
	mkdir -p "$ncpath"
	pv -w 80 $html/nextcloud-$ncversion.tar.bz2 | tar xjf - -C $html

	{
	mv $standardpath/* $ncpath/
	mv $standardpath/.* $ncpath/
	} &> /dev/null

	rm -f $html/nextcloud-$ncversion.tar.bz2
	rm -rf $standardpath
	sleep 1

	echo ""
	printf $green"Extract completed.\n"$reset
	echo ""
	sleep 1

printhead
echo ""
####################
##  PASSWORD-GEN  ##
####################

	printf $yellow"Let's do some magic... Generating usernames and passwords..\n"$reset
	echo ""

# Generate random Database-username
function vowel() {
s=aeoiu
p=$(( $RANDOM % 5))
    echo -n ${s:$p:1}
}
function consonant() {
s=bcdfghjklmnpqrstBCDFGHJKLMNPQRST
p=$(( $RANDOM % 32))
    echo -n ${s:$p:1}
}
dbuser1=`consonant; vowel; consonant; vowel; consonant; vowel; consonant`
dbuser2=${ncname}_${dbuser1}

# Limit dbuser to 16 characters
dbuser=${dbuser2:0:16}
sleep 1

dbname1=`consonant; vowel; consonant; vowel; consonant; vowel; consonant`
dbname="${ncname}_${dbname1}"

# Generate random Database-password
choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
dbpwd="$({
  choose 'abcdefghijklmnopqrstuvwxyz'
  choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  for i in $( seq 1 $(( 8 + RANDOM % 2 )) )
     do
        choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
     done
 } | sort -R | awk '{printf "%s",$1}')"

# Generate random Admin-password
choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
adminpwd="$({
  choose '0123456789'
  choose 'abcdefghijklmnopqrstuvwxyz'
  choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  for i in $( seq 1 $(( 10 + RANDOM % 2 )) )
     do
        choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
     done
 } | sort -R | awk '{printf "%s",$1}')"
sleep 1
printf $green"Done!\n"$reset
echo ""
sleep 1

if [ -z "$dbtype" ] || [ -z "$dbname" ] || [ -z "$dbuser" ] || [ -z "$dbpwd" ] || [ -z "$dbhost" ] || [ -z "$adminuser" ] || [ -z "$adminpwd" ] || [ -z "$ncpath" ] || [ -z "$ncname" ];
then

	echo ""
	printf $redbg"One or more variables are undefined. Aborting..."$reset
	echo ""
	sleep 1
	stty echo
	exit 0
else

#################
##  DATABASE  ##
#################
printf $yellow"Creating Database...\n"$reset
echo ""
{
if [[ "dbhost" = "localhost" ]]; then
	mysql -u $dbruser -p$database_root -e "CREATE DATABASE $dbname"
	mysql -u $dbruser -p$database_root -e "CREATE DATABASE $dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
	sleep 1
	mysql -u $dbruser -p$database_root -e "USE $dbname"
	sleep 1
	mysql -u $dbruser -p$database_root -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpwd'"
	sleep 1
else
	mysql -u $dbruser -p$database_root -h $dbhost -e "CREATE DATABASE $dbname"
	sleep 1
	mysql -u $dbruser -p$database_root -h $dbhost -e "USE $dbname"
	sleep 1
	mysql -u $dbruser -p$database_root -h $dbhost -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'%' IDENTIFIED BY '$dbpwd'"
	sleep 1
fi
} &> /dev/null
printf $green"Done! Continuing..\n"$reset
sleep 1

##################
##  AUTOCONFIG  ##
##################
echo ""
printf $yellow"Creating Autoconfig...\n"$reset
echo ""
sleep 2

# remove http:// and https:// from url to match trusted_domains requirements
url2=${url1#*//}

if [[ -n "$folder" ]]; then
	dir="$ncpath/data"
else
	len=${#ncpath}-1
	ncpath2="${ncpath:0:$len}"
	dir="$ncpath2/data"
fi

AUTOCONFIG='$AUTOCONFIG'
cat <<EOF > $ncpath/config/autoconfig.php
<?php
$AUTOCONFIG = array(
'dbtype' => "$dbtype",
'dbname' => "$dbname",
'dbuser' => "$dbuser",
'dbpass' => "$dbpwd",
'dbhost' => "$dbhost",
'dbtableprefix' => "",
'adminlogin' => "$adminuser",
'adminpass' => "$adminpwd",
'directory' => "$dir",
'trusted_domains' =>
  array (
    0 => "$url2",
  ),
  'overwrite.cli.url' => "$url1",
  'default_language' => 'de',
);
EOF
fi

# Check if any variable is empty - If true, print error and exit
if [ -z "$ncpath" ] || [ -z "$rootuser" ] || [ -z "$htuser" ] || [ -z "$htgroup" ];
then

	echo ""
	printf $redbg"One or more variables are undefined. Aborting...\n"$reset
	echo ""
	sleep 1
	stty echo
	exit 0
else
printf $green"Done!\n"$reset
echo ""
sleep 1
printf $yellow"Setting correct permissions...\n"$reset
echo ""
sleep 1

###################
##  PERMISSIONS  ##
###################
	touch ./nextcloud_permissions.sh
	cat <<EOF > ./nextcloud_permissions.sh
#!/bin/bash
if [ -z "$ncpath" ] || [ -z "$rootuser" ] || [ -z "$htuser" ] || [ -z "$htgroup" ];
then

	echo ""
	printf "\e[41mOne or more variables are undefined. Aborting...\e[0m\n"
	echo ""
	sleep 1
	exit 0
else
mkdir -p $ncpath/data
mkdir -p $ncpath/assets
mkdir -p $ncpath/updater

find ${ncpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ncpath}/ -type d -print0 | xargs -0 chmod 0750

chown -R ${rootuser}:${htgroup} ${ncpath}
chown -R ${htuser}:${htgroup} ${ncpath}/apps/
chown -R ${htuser}:${htgroup} ${ncpath}/assets/
chown -R ${htuser}:${htgroup} ${ncpath}/config/
chown -R ${htuser}:${htgroup} ${ncpath}/data/
chown -R ${htuser}:${htgroup} ${ncpath}/themes/
chown -R ${htuser}:${htgroup} ${ncpath}/updater/

chmod +x ${ncpath}/occ

if [ -f ${ncpath}/.htaccess ]
 then
  chmod 0644 ${ncpath}/.htaccess
  chown ${htuser}:${htgroup} ${ncpath}/.htaccess
fi
if [ -f ${ncpath}/data/.htaccess ]
 then
  chmod 0644 ${ncpath}/data/.htaccess
  chown ${rootuser}:${htgroup} ${ncpath}/data/.htaccess
fi
fi
EOF
	chmod +x nextcloud_permissions.sh
	./nextcloud_permissions.sh
	printf $green"Setting permissions completed...\n"$reset
	echo ""
	rm -f ./nextcloud_permissions.sh
	sleep 2
fi

# Install Nextcloud via autoconfig.php
printf $yellow"INDEXING...\n"$reset
if [ -z "$folder" ]; then
	url=$url1/index.php				# trigger for autoconfig.php
else
	url=$url1/$folder/index.php		# trigger for autoconfig.php
fi
{
curl $url
} &> /dev/null
echo ""
printf $green"INDEXING COMPLETE\n"$reset
echo ""
sleep 1
printf $green"Finishing setup...\n"$reset

#################
##  FINISHING  ##
#################

# enable 'no case match'
shopt -s nocasematch
while true; do progress; done &
	{
	# Check for APCu
	if [[ "$memcache" = "APCu" ]]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set memcache.local --value "\OC\Memcache\APCu"
	fi

	# Check for Display name value
	if [[ "$displayname" = "true" ]]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set allow_user_to_change_display_name --value 'true'
	fi

	# Check for updater channel
	if [[ "$rlchannel" = "daily" ]]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set updater.release.channel --value 'daily'
	elif [[ "$rlchannel" = "stable" ]]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set updater.release.channel --value 'stable'
	elif [[ "$rlchannel" = "beta" ]]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set updater.release.channel --value 'beta'
	elif [[ "$rlchannel" = "production" ]]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set updater.release.channel --value 'production'
	fi

	# Check for maintenance mode
	if [[ "$maintenance" = "true" ]]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set maintenance --value 'true'
	fi

	# Check for single user mode
	if [[ "$singleuser" = "true" ]]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set singleuser --value 'true'
	fi

	# Install Apps
	if [[ "$contactsinstall" = "true" ]]; then contactsinstall; fi
	if [[ "$calendarinstall" = "true" ]]; then calendarinstall; fi
	if [[ "$mailinstall" = "true" ]]; then mailinstall; fi
	if [[ "$notesinstall" = "true" ]]; then notesinstall; fi
	if [[ "$tasksinstall" = "true" ]]; then tasksinstall; fi
	if [[ "$galleryinstall" = "true" ]]; then galleryinstall; fi
	if [[ "$impinstall" = "true" ]]; then impersonateinstall; fi

	sudo -u ${htuser} php $ncpath/occ user:setting $adminuser settings email "$email"
	sudo -u ${htuser} php $ncpath/occ config:system:set default_language --value "$default_language"

	# Set SMTP
	if [ "$smtp" == "y" ] || [ "$smtp" == "Y" ]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_from_address --value 'admin'
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_smtpmode --value 'smtp'
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_domain --value "$smtpdomain"
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_smtpauthtype --value "$smtpauth"
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_smtpauth --value "$smtpauthreq"
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_smtphost --value "$smtphost"
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_smtpport --value "$smtpport"
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_smtpname --value "$smtpname"
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_smtppassword --value "$smtppwd"
		sudo -u ${htuser} php $ncpath/occ config:system:set mail_smtpsecure --value "$smtpsec"
	fi

	# Check for custom skeleton directory
	if [[ "$skeleton" = "none" ]]; then echo "";
	else
	sudo -u ${htuser} php $ncpath/occ config:system:set skeletondirectory --value "$skeleton"
	fi

	# Check for enable avatars
	if [[ "$enable_avatars" = "true" ]]; then
	sudo -u ${htuser} php $ncpath/occ config:system:set enable_avatars --value 'true'
	fi

	if [[ -n "$folder" ]]; then
		rewritevalue="/$folder"
	else
		rewritevalue='/'
	fi

	# Check for pretty URLs
	if [[ "$rewritebase" = "true" ]]; then
		sudo -u ${htuser} php $ncpath/occ config:system:set htaccess.RewriteBase --value "$rewritevalue"
		sudo -u ${htuser} php $ncpath/occ maintenance:update:htaccess
	fi

	# remove config.sample.php
	rm -f $ncpath/config/config.sample.php
echo ""
sleep 2
	} &> /dev/null

	kill $!; trap 'kill $!' SIGTERM

# disable 'no case match'
shopt -u nocasematch

echo ""
echo ""
printf $ugreen"Finished!\n"$reset
sleep 2
#################
##  ENDSCREEN  ##
#################

# Check for pretty URLs
if [[ "$rewritebase" = "true" ]]; then
len=${#url}-10
url="${url:0:$len}"
fi

touch /root/${ncname}_passwords.txt
# Store the passwords
{
echo "URL     		: $url"
echo "Nextcloud Admin   	: $adminuser"
echo "Nextcloud Password   	: $adminpwd"
echo ""
echo "Database type		: $dbtype"
echo "Database name		: $dbname"
echo "Database user		: $dbuser"
echo "Database password	: $dbpwd"
} > /root/${ncname}_passwords.txt

{
printhead
echo ""
echo "###################################################################"
echo " Congratulations. Nextcloud has now been successfully"
echo " installed on your server."
echo ""
echo " URL     		: $url"
echo " Nextcloud Admin   	: $adminuser"
echo " Nextcloud Password   	: $adminpwd"
echo ""
echo " Database type		: $dbtype"
echo " Database name		: $dbname"
echo " Database user		: $dbuser"
echo " Database password	: $dbpwd"
echo ""
echo "   (theses passwords are saved in /root/${ncname}_passwords.txt)"
echo "###################################################################"
echo ""
printf $green"Navigate to $url and enjoy Nextcloud!\n"$reset

	# Check for maintenance mode
	if [[ "$maintenance" = "true" ]]; then
		echo ""
		printf $red"Your system is in maintenance mode! \n"$reset
		echo ""
		echo "To disable maintenance mode type:"
		printf $green"sudo -u ${htuser} php $ncpath/occ maintenance:mode --off"$reset
		sleep 2
	fi
	# Check for singleuser mode
	if [[ "$singleuser" = "true" ]]; then
		echo ""
		printf $red"Your system is in singleuser mode! \n"$reset
		echo ""
		echo "To disable singleuser mode type:"
		printf $green"sudo -u ${htuser} php $ncpath/occ singleuser:mode --off"$reset
		sleep 2
	fi
rm -f nextcloud-$ncversion.tar.bz2
echo ""
} &>/dev/tty
stty echo
###############
##  RESTART  ##
###############

# Restart server if desired
read -t 1 -n 100 discard
installed=yes
if [[ "$installed" == "yes" ]] ; then
    while true; do
	stty echo
		echo -en "Do you want to restart your server now (y/n)? ";rsn=$(readOne)
		echo ""
        case $rsn in
            [Yy]* )
			stty echo
			break;;
            [Nn]* )
			stty echo
			exit;
        esac
    done
    shutdown -r now
fi
