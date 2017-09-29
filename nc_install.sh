#!/bin/bash
#
## Piet's Host ## - ©2017, https://piets-host.de
#
# Tested on:
# CentOS 6.8 & 7.4,
# Ubuntu 12.04, 14.04, 16.04,
# Debian 7 & 8,
# Fedora 23, 24 & 25,
#

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
# disable user input
stty -echo
clear

# Import sources
source functions.sh
source variables.sh
source apps.sh

# Set colors for printf output
red='\e[31m'
green='\e[32m'
yellow='\e[33m'
reset='\e[0m'
redbg='\e[41m'
lightred='\e[91m'
blue='\e[34m'
cyan='\e[36m'
ugreen='\e[4;32m'

while :; do
    case $1 in
        -h|-\?|--help|\?)   # Call "show_help" function , then exit.
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
		-i|--icon)
			if [ -n "$2" ]; then
				icon="$2"
				shift
			else
                printf $redbg'ERROR: "--icon" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
            ;;
		-c|--config)
			if [ -n "$2" ]; then
				if [ -f "$2" ]; then
					config_to_read="$2"
					isconfig="true"
			else
                printf $redbg'ERROR: "--config" requires a non-empty option argument.' >&2
				printf $reset"\n"
				stty echo
                exit 1
            fi
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
		--cron)
			if [ -n "$2" ]; then
				cron="$2"
				shift
			else
                printf $redbg'ERROR: "--cron" requires a non-empty option argument.' >&2
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

# Set Header
header=' _____ _      _         _    _           _
|  __ (_)    | |       | |  | |         | |
| |__) |  ___| |_ ___  | |__| | ___  ___| |_
|  ___/ |/ _ \ __/ __| |  __  |/ _ \/ __| __|	+-+-+-+-+
| |   | |  __/ |_\__ \ | |  | | (_) \__ \ |_ 	| v 2.0 |
|_|   |_|\___|\__|___/ |_|  |_|\___/|___/\__|	+-+-+-+-+'

# Set color for Status
check_ok=$green"   OK  "$reset
check_miss=$redbg"MISSING"$reset

# Define latest Nextcloud version
ncrepo="https://download.nextcloud.com/server/releases"

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Root privileges required, type: sudo -i"; stty echo; exit 1; }

printhead
echo ""
# Read JSON config
if [[ "$isconfig" = "true" ]]; then
	begin=$(date +%s)
	jsonconfig
else
	# Apps
	contactsinstall='true'
	calendarinstall='true'
	mailinstall='false'
	notesinstall='false'
	tasksinstall='false'
	galleryinstall='false'
	impinstall='false'
fi

###################################
######   BEFORE SETUP START   #####
###################################

printf "Checking minimal system requirements...\n"
sleep 4 & spinner
echo ""

# Check CPUs
cpus="$(nproc)"
if [[ "${cpus}" -lt 2 ]]; then
	echo ""
	printf $red"Attention: 2 CPUs recommended to install Nextcloud!\n"$reset
	printf $red"Current CPU: ("$((cpus))")\n"$reset
	anykey
else
	printf $green"CPU for Nextcloud OK! ("$((cpus))")\n"$reset
	echo ""
fi

# Check RAM
ram="$(awk '/MemTotal/{print $2}' /proc/meminfo)"
if [ "$ram" -lt "$((1*1002400))" ]; then
	echo ""
	printf $red"Attention: 1 GB RAM recommended to install Nextcloud!\n"$reset
	printf $red"Current RAM is: ("$((ram/1002400))" GB)\n"$reset
	anykey
else
    printf $green"Enough RAM for Nextcloud found! ("$((ram/1002400))" GB)\n"$reset
fi
echo ""

# Check internet connection
wget -q --tries=10 --timeout=10 https://www.google.com -O /tmp/test.pgx &> /dev/null
if [ ! -s /tmp/test.pgx ]
then
	printf $red"Sorry, no Internet Connection available. Try again later!\n"$reset
	sleep 2
	echo ""
	exit 1
fi

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
sleeping

if [[ "$os" = "CentOs" && ("$ver" = "6" || "$ver" = "7" ) ||
      "$os" = "Ubuntu" && ("$ver" = "12.04" || "$ver" = "14.04" || "$ver" = "16.04"  ) ||
      "$os" = "debian" && ("$ver" = "7" || "$ver" = "8" ) ||
	"$os" = "fedora" && ("$ver" = "23" || "$ver" = "24" || "$ver" = "25") ]]; then
	printf $green"Very Good! Your OS is compatible.\n"$reset
	echo ""
	sleeping
else
	printf $red"Unfortunately, this OS is not supported by Piet's Host Installation-Script for Nextcloud.\n"$reset
	sleeping2
	abort
fi
sleeping

if [[ "$os" = "Ubuntu" && ("$ver" = "12.04" || "$ver" = "14.04" || "$ver" = "16.04"  ) ]]; then
	if [[ "$overwrite" = "true" ]]; then
		#Check for Plesk installation
		echo "checking additional control panels..."
		echo ""
		if dpkg -l | grep -q psa; then
			plesk
		fi
		rootuser='root'
		dbruser='root'
		htgroup='www-data'
		htuser='www-data'
	else
		if [[ "$isconfig" = "true" ]]; then
			readusers
		fi
	fi

elif [[ "$os" = "debian" && ("$ver" = "7" || "$ver" = "8" ) ]]; then
	if [[ "$overwrite" = "true" ]]; then
		#Check for Plesk installation
		echo "checking additional control panels..."
		echo ""
		if dpkg -l | grep -qw psa; then
			plesk
		fi
		rootuser='root'
		dbruser='root'
		htgroup='www-data'
		htuser='www-data'
	else
		if [[ "$isconfig" = "true" ]]; then
			readusers
		fi
	fi

elif [[ "$os" = "CentOs" && ("$ver" = "6" || "$ver" = "7" ) ]]; then
	if [[ "$overwrite" = "true" ]]; then
		#Check for Plesk installation
		echo "checking additional control panels..."
		echo ""
		if rpm -qa | grep -q psa; then
			plesk
		fi
		rootuser='root'
		dbruser='root'
		htgroup='apache'
		htuser='apache'
	else
		if [[ "$isconfig" = "true" ]]; then
			readusers
		fi
	fi

elif [[ "$os" = "fedora" && ("$ver" = "23" || "$ver" = "25") ]]; then
	if [[ "$overwrite" = "true" ]]; then
		#Check for Plesk installation
		echo "checking additional control panels..."
		echo ""
		if rpm -qa | grep -qw psa; then
			plesk
		fi
		rootuser='root'
		dbruser='root'
		htgroup='apache'
		htuser='apache'
	else
		if [[ "$isconfig" = "true" ]]; then
			readusers
		fi
	fi
fi

if [[ "$depend" = "false" ]]; then
		printf $yellow"Skipping dependencies check...\n"$reset
		sleeping
else
	printf $yellow"Installing dependencies...(may take some time)\n"$reset
{
if [[ "$os" = "Ubuntu" && ("$ver" = "12.04" || "$ver" = "14.04" || "$ver" = "16.04"  ) ]]; then
	dpkg -l | grep -qw pv || apt-get install pv -y
	dpkg -l | grep -qw bzip2 || apt-get install bzip2 -y
	dpkg -l | grep -qw rsync || apt-get install rsync -y
	dpkg -l | grep -qw bc || apt-get install bc -y
	dpkg -l | grep -qw xmlstarlet || apt-get install xmlstarlet -y
	dpkg -l | grep -qw php-zip || apt-get install php-zip -y
	dpkg -l | grep -qw php-dom || apt-get install php-dom -y
	dpkg -l | grep -qw php-gd || apt-get install php-gd -y
	dpkg -l | grep -qw php-curl || apt-get install php-curl -y
	dpkg -l | grep -qw php-mbstring || apt-get install php-mbstring -y
	dpkg -l | grep -qw curl || apt-get install curl -y
	service apache2 restart
	if [[ "$overwrite" = "true" ]]; then
		rootuser='root'
		dbruser='root'
		htgroup='www-data'
		htuser='www-data'
	else
		if [[ "$isconfig" = "true" ]]; then
			readusers
		fi
	fi

elif [[ "$os" = "debian" && ("$ver" = "7" || "$ver" = "8" ) ]]; then
	apt-get install pv -y
	if dpkg -l | grep -qw bzip2; then echo "bzip2 INSTALLIERT"; else apt-get install bzip2 -y; fi;
	if dpkg -l | grep -qw rsync; then echo "rsync INSTALLIERT"; else apt-get install rsync -y; fi;
	if dpkg -l | grep -qw bc; then echo "bc INSTALLIERT"; else apt-get install bc -y; fi;
	if dpkg -l | grep -qw xmlstarlet; then echo "xmlstarlet INSTALLIERT"; else apt-get install xmlstarlet -y; fi;
	if dpkg -l | grep -qw php5-gd; then echo "php5-gd INSTALLIERT"; else apt-get install php5-gd -y; fi;
	if dpkg -l | grep -qw php5-curl; then echo "php-5curl INSTALLIERT"; else apt-get install php5-curl -y; fi;
	apt-get install curl -y
	service apache2 restart
	if [[ "$overwrite" = "true" ]]; then
		rootuser='root'
		dbruser='root'
		htgroup='www-data'
		htuser='www-data'
	else
		if [[ "$isconfig" = "true" ]]; then
			readusers
		fi
	fi

elif [[ "$os" = "CentOs" && ("$ver" = "6" || "$ver" = "7" ) ]]; then
	rpm -qa | grep -qw pv || yum install pv -y
	rpm -qa | grep -qw bc || yum install bc -y
	rpm -qa | grep -qw bzip2 || yum install bzip2 -y
	rpm -qa | grep -qw rsync || yum install rsync -y
	rpm -qa | grep -qw php-process || yum install php-process -y
	rpm -qa | grep -qw xmlstarlet || yum install xmlstarlet -y
	rpm -qa | grep -qw curl || yum install curl -y
	if [[ "$overwrite" = "true" ]]; then
		rootuser='root'
		dbruser='root'
		htgroup='apache'
		htuser='apache'
	else
		if [[ "$isconfig" = "true" ]]; then
			readusers
		fi
	fi

elif [[ "$os" = "fedora" && ("$ver" = "23" || "$ver" = "25") ]]; then
	rpm -qa | grep -qw pv || dnf install pv -y
	rpm -qa | grep -qw bc || dnf install bc -y
	rpm -qa | grep -qw bzip2 || dnf install bzip2 -y
	rpm -qa | grep -qw rsync || dnf install rsync -y
	rpm -qa | grep -qw php-process || dnf install php-process -y
	rpm -qa | grep -qw xmlstarlet || dnf install xmlstarlet -y
	rpm -qa | grep -qw curl || dnf install curl -y
	rpm -qa | grep -qw php-zip || dnf install php-zip -y
	rpm -qa | grep -qw php-gd || dnf install php-gd -y
	service httpd restart
	if [[ "$overwrite" = "true" ]]; then
		rootuser='root'
		dbruser='root'
		htgroup='apache'
		htuser='apache'
	else
		if [[ "$isconfig" = "true" ]]; then
			readusers
		fi
	fi
fi
} &> /dev/null
if [ "$perm" = "plesk" ]; then
	echo ""
	printf $cyan"Plesk detected...Setting DB-user and DB-password\n"$reset
	sleeping2
fi
fi

#################################
######   BEFORE SETUP END   #####
#################################

# Check Status on startup
folderstat="$check_ok"
iconstat="$check_ok"
check

#################################
######   INITIALIZATION    ######
#################################

# enable user input
stty echo

# clear user input
read -t 1 -n 100 discard

if [[ "$isconfig" = "true" ]]; then
	sleeping2
else

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
fi
echo ""
stty -echo
printhead
echo ""

####################################
######   INITIALIZATION END   ######
####################################

###################################
######   Setup Page 1 Start   #####
###################################

regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
regexmail="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
regexhttps='(https|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
stty echo

if [[ "$isconfig" = "true" ]]; then
	echo ""
	echo "Skipping Page 1"
else
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
			anykey
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
	abort
fi
done
fi
stty -echo
standardpath=$html/nextcloud
ncpath=$html/$folder
sleeping
#################################
######   Setup Page 1 End   #####
#################################

# Check if Nextcloud is already installed.

if [ -f "$ncpath/occ" ]; then
	chmod +x $ncpath/occ
	CURRENTVERSION=$(sudo -u $htuser php $ncpath/occ status | grep "versionstring" | awk '{print $3}')
	echo ""
	printf $redbg"Nextcloud is already installed...\n"$reset
	echo ""
	echo "If your version isn't up to date make use of the Piet's Host ncupdate-script."
	echo ""
	sleeping2
	abort
else
	echo ""
	printf $green"No Nextcloud installation found! Installing continues...\n"$reset
	echo ""
	sleeping3
fi
stty echo

######### Warning Apache & MySQL
{
type mysql >/dev/null 2>&1
} &> /dev/null
if [ $? -eq 0 ]; then
	printf $green"MySQL installation found! Installing continues...\n"$reset
	echo ""
	sleeping3
else
	printf $redbg"MySQL is not installed. Aborting...\n"$reset
	sleeping3
	abort
fi

{
ps -A | grep 'apache\|httpd\|nginx'
} &> /dev/null
if [ $? -eq 0 ]; then
	printf $green"Apache/nginx installation found! Installing continues...\n"$reset
	echo ""
	sleeping3
else
	printf $redbg"Apache/nginx is not installed/not running. Aborting..."$reset
	echo ""
	sleeping3
	abort
fi
iconstat="$check_ok"
#########

###################################
######   Setup Page 2 Start   #####
###################################
if [[ "$isconfig" = "true" ]]; then
	echo "Skipping Page 2"
else
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
printf "  8   |  $cronstat   |         cronjob: | "$cron"\n"
printf "  9   |  $iconstat   |         favicon: | "$icon"\n"
echo "------+------------+------------------+------------------------------------"
printf "Type [1-9] to change value or ${cyan}[s]${reset} to save and go to next page\n"
printf "${red}[q]${reset} Quit\n"
echo -en "Enter [1-9], [s] or [q]: ";key3=$(readOne)

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
		anykey
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
	[  -z "$htuser" ] && htusrstat="$check_miss" || htusrstat="$check_ok"
	if [ "$perm" = "plesk" ]; then
		rootuser="$htuser"
	fi

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
	if [ "$perm" = "plesk" ]; then
		rootuser="$htuser"
	else
		echo -n "Enter root user (usually: root): "
		read rootuser
		while ! id "$rootuser" >/dev/null 2>&1; do
			printf $redbg"This user does not exist! Enter root user: "$reset
			read rootuser
		done
	[  -z "$rootuser" ] && rootusrstat="$check_miss" || rootusrstat="$check_ok"
	fi

  elif [ "$key3" = "8" ]; then
	if [ "$cron" = "true" ]; then
		cron='false'
		cronstat="$check_ok"
		printf $red"Cronjob turned off\n"$reset
		sleep 1
	elif [ "$cron" = "false" ]; then
		cron='true'
		cronstat="$check_ok"
		printf $green"Cronjob turned on\n"$reset
		sleep 1
	fi

  elif [ "$key3" = "9" ]; then
	echo ""
	stty echo
	echo -n "Enter favicon-location (e.g. /home/favicon.ico): "
	read icon
	iconstat="$check_ok"

  elif [ "$key3" = "s" ]; then
	stty echo
	if [ -z "$email" ] || [ -z "$htuser" ] || [ -z "$htgroup" ] || [ -z "$rootuser" ] || [ -z "$dbruser" ] || [ -z "$adminuser" ] || [ -z "$database_root" ]; then
		printf $redbg"One or more variables are undefined (Page 2). Aborting..."$reset
        	sleep 3
        	continue
	else
		echo ""
        	echo "-----------------------------"
	break
	fi
  elif [ "$key3" = "q" ]; then
	abort
  fi
done
fi
sleeping
#################################
######   Setup Page 2 End   #####
#################################

###################################
######   Setup Page 3 Start   #####
###################################
if [[ "$isconfig" = "true" ]]; then
	echo ""
	echo "Skipping Page 3"
else
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
		sleeping
	elif [ "$displayname" = "false" ]; then
		displayname='true'
		dpnamestat="$check_ok"
		printf $green"allow change of display name set to true\n"$reset
		sleeping
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
		sleeping
	elif [ "$maintenance" = "false" ]; then
		maintenance='true'
		maintstat="$check_ok"
		printf $green"maintenance mode set to true\n"$reset
		sleeping
	fi

elif [ "$key4" = "5" ]; then
	if [ "$singleuser" = "true" ]; then
		singleuser='false'
		singlestat="$check_ok"
		printf $red"singleuser mode set to false\n"$reset
		sleeping
	elif [ "$singleuser" = "false" ]; then
		singleuser='true'
		singlestat="$check_ok"
		printf $green"singleuser mode set to true\n"$reset
		sleeping
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
		sleeping
	elif [ "$enable_avatars" = "false" ]; then
		enable_avatars='true'
		enavastat="$check_ok"
		printf $green"enable avatars set to true\n"$reset
		sleeping
	fi

elif [ "$key4" = "9" ]; then
	if [ "$rewritebase" = "true" ]; then
		rewritebase='false'
		rewritestat="$check_ok"
		printf $red"RewriteBase disabled\n"$reset
		sleeping
	elif [ "$rewritebase" = "false" ]; then
		rewritebase='true'
		rewritestat="$check_ok"
		printf $green"RewriteBase enabled\n"$reset
		sleeping
	fi

elif [ "$key4" = "s" ]; then
	echo ""
	stty echo
	if [ -z "$rlchannel" ] || [ -z "$memcache" ]; then
		printf $redbg"One or more variables are undefined (Page 3). Aborting..."$reset
		sleep 3
        	continue
	else
		echo ""
        	echo "-----------------------------"
	break
	fi
elif [ "$key4" = "q" ]; then
	abort
fi
done
fi
#################################
######   Setup Page 3 End   #####
#################################

#################################
######   SMTP-Setup Start   #####
#################################

# ask for SMTP-Setup
if [[ "$isconfig" = "true" ]]; then
	echo ""
	echo "Skipping SMTP-Setup"
	if [ "$smtp" == "y" ] || [ "$smtp" == "Y" ]; then
		printhead
		echo ""
		smtpsetup
	fi
elif [ "$smtp" == "y" ] || [ "$smtp" == "Y" ]; then
	printhead
	echo ""
	smtpsetup
elif [ "$smtp" == "n" ] || [ "$smtp" == "N" ]; then
	printhead
	echo ""
	printf "Skipping SMTP Setup..."
	sleeping
elif [ -z "$smtp" ]; then
	printhead
	echo ""
	echo -en "Do you want to setup SMTP (y/n)? ";smtp=$(readOne)
	if [ "$smtp" == "y" ] || [ "$smtp" == "Y" ]; then
		printhead
		echo ""
		smtpsetup
	else
		printhead
		echo ""
		printf "Skipping SMTP Setup..."
		sleeping
	fi
fi
sleeping
###############################
######   SMTP-Setup End   #####
###############################

#################################
######   Apps-Setup Start   #####
#################################

# ask for Apps-Setup
if [[ "$isconfig" = "true" ]]; then
	echo ""
	echo "Skipping Apps-Setup"
	sleeping
	if [ "$appsinstall" == "y" ] || [ "$appsinstall" == "Y" ]; then
		echo ""
		installapps
	fi
elif [ "$appsinstall" == "y" ] || [ "$appsinstall" == "Y" ]; then
	printhead
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
	sleeping
elif [ -z "$appsinstall" ]; then
	printhead
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
		sleeping
	fi
fi
stty -echo

###############################
######   Apps-Setup End   #####
###############################
if [[ "$isconfig" = "true" ]]; then
	echo ""
else
	printhead
	echo ""
fi

chown ${htuser}:${htgroup} $html

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
	sleeping
	rm -f nextcloud-$ncversion.tar.bz2
else
	printf $lightred"Nextcloud version ${version} doesn't exist.\n"$reset
	echo ""
	printf "Please check available versions here: ${ugreen}${ncrepo}\n"$reset
	abort
fi

# Check if variables are set
if [ -z "$html" ] || [ -z "$ncpath" ] || [ -z "$ncname" ] || [ -z "$dbhost" ] || [ -z "$dbtype" ] || [ -z "$htuser" ] || [ -z "$htgroup" ] || [ -z "$rootuser" ] || [ -z "$standardpath" ] || [ -z "$ncrepo" ] || [ -z "$ncversion" ]; then
	echo ""
	printf $redbg"One or more variables are undefined (ALL). Aborting...\n"$reset
	echo ""
	sleeping
	abort
elif [ -z "$url1" ] || [ -z "$ncname" ] || [ -z "$html" ] || [ -z "$dbtype" ] || [ -z "$dbhost" ]; then
	printf $redbg"One or more variables are undefined (HTML/DB Parameters). Aborting..."$reset
	sleeping
	abort
elif [ -z "$rlchannel" ] || [ -z "$memcache" ] || [ -z "$displayname" ] || [ -z "$maintenance" ] || [ -z "$singleuser" ] || [ -z "$skeleton" ] || [ -z "$default_language" ] || [ -z "$enable_avatars" ] || [ -z "$rewritebase" ]; then
	printf $redbg"One or more variables are undefined (config Parameters) . Aborting..."$reset
	sleeping
	abort
else

# Install Warning
if [[ "$isconfig" = "true" ]]; then
	echo ""
	echo "Performing install now"
	sleeping

################################
######   Check variables   #####
################################
if ! [[ "$smtpport" =~ ^[0-9]+$ ]]; then
	echo ""
	printf $redbg"Wrong SMTP Port format, only numbers allowed. Aborting...\n"$reset
	abort
fi
if ! [ "$smtpsec" = "tls" ] || [ "$smtpsec" = "ssl" ] || [ "$smtpsec" = "none" ]; then
	echo ""
	printf $redbg"Wrong SMTP type. Aborting...\n"$reset
	abort
fi
if ! [[ $url1 =~ $regex ]]; then
	echo ""
	printf $redbg"Wrong input format. No valid URL found. Aborting...\n"$reset
	abort
fi
if ! [[ -d $html ]]; then
	echo ""
	printf $redbg"HTML directory does not exist. Aborting...\n"$reset
	abort
fi
if ! [[ $email =~ $regexmail ]]; then
	echo ""
	printf $redbg"Wrong E-Mail format. Aborting...\n"$reset
	abort
fi

if ! mysqlcheck ; then
	echo ""
	printf $redbg"Database Connection couldn't be established... Aborting\n"$reset
	abort
fi
if ! id "$htuser" >/dev/null 2>&1; then
	echo ""
	printf $redbg"WWW-User $htuser does not exist. Aborting...\n"$reset
	abort
fi
if ! id "$rootuser" >/dev/null 2>&1; then
	echo ""
	printf $redbg"rootuser $rootuser does not exist. Aborting...\n"$reset
	abort
fi
if ! grep -q $htgroup /etc/group; then
	echo ""
	printf $redbg"WWW-Group $htgroup does not exist. Aborting...\n"$reset
	abort
fi

else
echo ""
echo "Performing install in 5 seconds.."
echo ""
printf "  |====>               |   (20%%)\r"
sleeping
printf "  |=======>            |   (40%%)\r"
sleeping
printf "  |===========>        |   (60%%)\r"
sleeping
printf "  |===============>    |   (80%%)\r"
sleeping
printf "  |===================>|   (100%%)\r"
printf "\n"
fi
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
if [ -f $html/nextcloud-$ncversion.tar.bz2 ]; then
	printf "Download of nextcloud-$ncversion.tar.bz2 ${green}successfull\n"$reset
	echo ""
else
	echo "Oh no! Something went wrong with the download"
	abort
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
sleeping

echo ""
printf $green"Extract completed.\n"$reset
echo ""
sleeping

printhead
echo ""
####################
##  PASSWORD-GEN  ##
####################

printf $yellow"Let's do some magic... Generating usernames and passwords..\n"$reset
echo ""

# Generate random Database-username
dbuser1=`consonant; vowel; consonant; vowel; consonant; vowel; consonant`
dbuser2=${ncname}_${dbuser1}

# Limit dbuser to 16 characters
dbuser=${dbuser2:0:16}
sleeping

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
sleeping
printf $green"Done!\n"$reset
echo ""
sleeping

if [ -z "$dbtype" ] || [ -z "$dbname" ] || [ -z "$dbuser" ] || [ -z "$dbpwd" ] || [ -z "$dbhost" ] || [ -z "$adminuser" ] || [ -z "$adminpwd" ] || [ -z "$ncpath" ] || [ -z "$ncname" ];
then
	echo ""
	printf $redbg"One or more variables are undefined. Aborting..."$reset
	sleeping
	abort
else

#################
##  DATABASE  ##
#################
printf $yellow"Creating Database...\n"$reset
echo ""
{
if [[ "dbhost" = "localhost" ]]; then
	mysql -u $dbruser -p$database_root -e "CREATE DATABASE $dbname"
	#mysql -u $dbruser -p$database_root -e "CREATE DATABASE $dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
	sleeping
	mysql -u $dbruser -p$database_root -e "USE $dbname"
	sleeping
	mysql -u $dbruser -p$database_root -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpwd'"
	sleeping
else
	mysql -u $dbruser -p$database_root -h $dbhost -e "CREATE DATABASE $dbname"
	sleeping
	mysql -u $dbruser -p$database_root -h $dbhost -e "USE $dbname"
	sleeping
	mysql -u $dbruser -p$database_root -h $dbhost -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'%' IDENTIFIED BY '$dbpwd'"
	sleeping
fi
} &> /dev/null
printf $green"Done! Continuing..\n"$reset
sleeping

##################
##  AUTOCONFIG  ##
##################
echo ""
printf $yellow"Creating Autoconfig...\n"$reset
echo ""
sleeping2

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
  'default_language' => "$default_language",
);
EOF
fi

# Check if any variable is empty - If true, print error and exit
if [ -z "$ncpath" ] || [ -z "$rootuser" ] || [ -z "$htuser" ] || [ -z "$htgroup" ]; then
	echo ""
	printf $redbg"One or more variables are undefined. Aborting...\n"$reset
	sleeping
	abort
else
	printf $green"Done!\n"$reset
	echo ""
	sleeping
	printf $yellow"Setting correct permissions...\n"$reset
	echo ""
	sleeping

###################
##  PERMISSIONS  ##
###################

if [ "$perm" = "plesk" ]; then
	chdir="0755"
	chfile="0644"
else
	chdir="0750"
	chfile="0640"
fi
	touch ./nextcloud_permissions.sh
	cat <<EOF > ./nextcloud_permissions.sh
#!/bin/bash
if [ -z "$ncpath" ] || [ -z "$rootuser" ] || [ -z "$htuser" ] || [ -z "$htgroup" ];
then

	echo ""
	printf "\e[41mOne or more variables are undefined. Aborting...\e[0m\n"
	echo ""
	sleeping
	exit 0
else
mkdir -p $ncpath/data
mkdir -p $ncpath/assets
mkdir -p $ncpath/updater

find ${ncpath}/ -type f -print0 | xargs -0 chmod ${chfile}
find ${ncpath}/ -type d -print0 | xargs -0 chmod ${chdir}

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

if [ "$perm" = "plesk" ]; then
	chown ${htuser}:psaserv $ncpath
fi
	printf $green"Setting permissions completed...\n"$reset
	echo ""
	rm -f ./nextcloud_permissions.sh
	sleeping2
fi

# Install Nextcloud via autoconfig.php
printf $yellow"INDEXING...\n"$reset
if [ -z "$folder" ]; then
	url=$url1/index.php				# trigger for autoconfig.php
else
	url=$url1/$folder/index.php		# trigger for autoconfig.php
fi
{
curl -k $url
} &> /dev/null
echo ""
printf $green"INDEXING COMPLETE\n"$reset
echo ""
sleeping
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

	# enable Cronjob
	if [[ "$cron" = "true" ]];then
		sudo -u ${htuser} php $ncpath/occ config:app:set core backgroundjobs_mode --value="cron"
		crontab -u ${htuser} -l > cron
		echo "*/15  *  *  *  * php $ncpath/cron.php" >> cron
		crontab -u ${htuser} cron
	fi

	# move favicon
	if [ -f $icon ]; then
		cp $icon $ncpath/core/img/favicon.ico
		chown ${rootuser}:${htgroup} $ncpath/core/img/favicon.ico
	fi

	# remove config.sample.php
	rm -f $ncpath/config/config.sample.php

	# Configure Upload and Filesize
	sed -i 's/  php_value upload_max_filesize.*/# php_value upload_max_filesize 511M/g' "$ncpath"/.htaccess
	sed -i 's/  php_value post_max_size.*/# php_value post_max_size 511M/g' "$ncpath"/.htaccess
	sed -i 's/  php_value memory_limit.*/# php_value memory_limit 512M/g' "$ncpath"/.htaccess

	echo ""
	sleeping2
} &> /dev/null

kill $!; trap 'kill $!' SIGTERM

# disable 'no case match'
shopt -u nocasematch

echo ""
echo ""
printf $ugreen"Finished!\n"$reset
sleeping2
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
		sleeping2
	fi
	# Check for singleuser mode
	if [[ "$singleuser" = "true" ]]; then
		echo ""
		printf $red"Your system is in singleuser mode! \n"$reset
		echo ""
		echo "To disable singleuser mode type:"
		printf $green"sudo -u ${htuser} php $ncpath/occ singleuser:mode --off"$reset
		sleeping2
	fi
rm -f nextcloud-$ncversion.tar.bz2
echo ""
} &>/dev/tty
stty echo
###############
##  RESTART  ##
###############

# Restart server if desired
if [[ "$isconfig" = "true" ]]; then
	if [[ "$rebootsrv" == "true" ]] ; then
		shutdown -r now
	else
		stty echo
		end=$(date +%s)
		tottime=$(expr $end - $begin)
		echo "Script completed successfully in $tottime seconds"
		exit 0
	fi
else
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
fi
