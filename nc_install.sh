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

##################################
######   DEFAULT VAR START   #####
##################################

#	Uncomment if you want to set the database root password (useful,
#	if you want to install multiple instances of Nextcloud)
#database_root='P@s$w0rd!'

url1="http://example.com"
ncname=nextcloud1
dbhost=localhost
dbtype=mysql
htuser='apache'  	# Webserver-User (CentOS: apache, suseLinux: wwwrun, etc..)
htgroup='apache'	# Webserver-Group (CentOS: apache, suseLinux: www, etc...)
rootuser='root'

# E-mail
email='mail@example.com'
smtpauth="LOGIN"
smtpport="587"
smtpname="admin@example.com"
smtpsec="tls"
smtppwd='password1234!'
smtpauthreq=1

# Others
displayname='true'
rlchannel='stable'
memcache='APCu'
maintenance='false'
singleuser='false'

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

header=' ______ __         __           _______               __
|   __ \__|.-----.|  |_.-----. |   |   |.-----.-----.|  |_
|    __/  ||  -__||   _|__ --| |       ||  _  |__ --||   _|
|___|  |__||_____||____|_____| |___|___||_____|_____||____|'

# Set color for Status
check_ok=$green"   OK  "$reset
check_miss=$redbg"MISSING"$reset

# Define latest Nextcloud version
ncrepo="https://download.nextcloud.com/server/releases"

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, type: sudo -i"; exit 1; }

##########################################################################################

# Check Status on startup
function check(){
[  -z "$url1" ] && domainstat="$check_miss" || domainstat="$check_ok"
[  -z "$ncname" ] && namestat="$check_miss" || namestat="$check_ok"
[  -z "$html" ] && htmlstat="$check_miss" || htmlstat="$check_ok"
[  -z "$backup" ] && backupstat="$check_miss" || backupstat="$check_ok"
[  "$folder" ] && folderstat="$check_ok"
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
[  -z "$database_root" ] && dbrootstat="$check_miss" || dbrootstat="$check_ok"
[  -z "$smtpdomain" ] && smtpdomainstat="$check_miss" || smtpdomainstat="$check_ok"
[  -z "$displayname" ] && dpnamestat="$check_miss" || dpnamestat="$check_ok"
[  -z "$rlchannel" ] && rlchanstat="$check_miss" || rlchanstat="$check_ok"
[  -z "$memcache" ] && memstat="$check_miss" || memstat="$check_ok"
[  -z "$maintenance" ] && maintstat="$check_miss" || maintstat="$check_ok"
[  -z "$singleuser" ] && singlestat="$check_miss" || singlestat="$check_ok"
}
###################################
######   BEFORE SETUP START   #####
###################################

printf $green"$header"$reset
echo ""
echo ""

printf "Checking minimal system requirements..."
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

echo ""
printf $yellow"Detected : $os $ver $arch\n"$reset
echo ""
sleep 1

if [[ "$os" = "CentOs" && ("$ver" = "6" || "$ver" = "7" ) ||
      "$os" = "Ubuntu" && ("$ver" = "12.04" || "$ver" = "14.04" || "$ver" = "16.04"  ) ||
      "$os" = "debian" && ("$ver" = "7" || "$ver" = "8" ) || 
	  "$os" = "fedora" && ("$ver" = "23" || "$ver" = "25") ]]; then
    echo ""
	printf $green"Very Good! Your OS is compatible.\n"$reset
	sleep 1
else
	echo ""
    printf $red"Unfortunately, this OS is not supported by Piet's Host Install-script for Nextcloud.\n"$reset
    echo ""
	sleep 2
	exit 1
fi
sleep 1

echo ""
echo ""
printf $yellow"Installing dependencies...\n"$reset

{
if [[ "$os" = "Ubuntu" && ("$ver" = "12.04" || "$ver" = "14.04" || "$ver" = "16.04"  ) ]]; then
	 sudo apt-get install -y pv bzip2 rsync
elif [[ "$os" = "CentOs" && ("$ver" = "6" || "$ver" = "7" ) ]]; then
	yum install -y pv bzip2 rsync php-process
elif [[ "$os" = "fedora" && ("$ver" = "23" || "$ver" = "25") ]]; then
	dnf install pv bzip2 rsync php-process
fi
} &> /dev/null

#################################
######   BEFORE SETUP END   #####
#################################

#################################
######   INITIALIZATION    ######
#################################

clear
printf $green"$header"$reset
echo ""
echo ""

  echo "--------------------------------------------------------"
  echo "    Welcome to Piet's Host Nextcloud Install-Script     "
  echo "------+------------------------------------------+------"
  ########    |------------------------------------------|"$var
  echo "      |    This Script will install Nextcloud    |"
  echo "      |    for you. To make it work, you have    |"
  echo "      |      to enter some variables on the      |"
  echo "      |             following pages.             |"
  echo "      |    Please read the documentation for     |"
  echo "      |     further information, what syntax     |"
  echo "      |    is required to make the script work   |"
  echo "      |                                          |"
  printf "      |  $yellow Database-Name, Database-password and  $reset |\n"
  printf "      |    $yellow Admin-password will be generated    $reset |\n"
  printf "      |              $yellow automatically.            $reset |\n"
  echo "------+------------------------------------------+------"
  echo "      |                                          |"
  echo "------+------------------------------------------+------"
read -n1 -r -p "      |   Press any key to continue..." key

if [ "$key" = '' ]; then
	return
fi
echo ""

#################################
######   INITIALIZATION    ######
#################################

##########################################################################################

###################################
######   Setup Page 1 Start   #####
###################################

html='/var/www/html' # full installation path
folder='nextcloud1'
backup=$html/backup
regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
regexmail="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

check
clear
while true; do
  clear
printf $green"$header"$reset
echo ""
echo ""

  echo "--------------------------------------------------------------------------"
  echo "                    Setup			Page 1/3"
  echo "------+------------+-----------------+------------------------------------"
  echo "  Nr. |   Status   |                 |    value"
  echo "------+------------+-----------------+------------------------------------"
  ###########    |xx-----------xxx|xxxxxxxxxXXXXXX:x|x"$var
  printf "  1   |  $domainstat   |         Domain: | "$url1"\n"
  printf "  2   |  $namestat   |           Name: | "$ncname"\n"
  printf "  3   |  $htmlstat   |      Directory: | "$html"\n"
  printf "  4   |  $backupstat   |         backup: | "$backup"\n"
  printf "  5   |  $folderstat   |         folder: | "$folder"\n"
  echo ""
  printf "  6   |  $dbtypestat   |        DB-Type: | "$dbtype"\n"
  printf "  7   |  $dbhoststat   |        DB-Host: | "$dbhost"\n"
  echo "------+------------+-----------------+------------------------------------"
  printf "Type [1-7] to change value or ${cyan}[s]${reset} to save and go to next page\n"
  printf "${red}[q]${reset} Quit\n"
  echo -n "Enter [1-7], [s] or [q]: ";read key1

  if [ "$key1" = "1" ]; then
  	echo -n "Enter url (with http:// or https://): "
	read url1

	# Check for correct input
	if [[ $url1 =~ $regex ]]; then
		[  -z "$url1" ] && domainstat="$check_miss" || domainstat="$check_ok"
	else
		printf $redbg"Wrong input format. Enter a valid URL..."$reset
		url1="http://example.com"
        sleep 3
        continue
	fi

  elif [ "$key1" = "2" ]; then
	echo -n "Enter name: "
	read ncname
	[  -z "$ncname" ] && namestat="$check_miss" || namestat="$check_ok"

  elif [ "$key1" = "3" ]; then
	echo -n "Enter html-directory (e.g. /var/www/html): "
	read html

	# Check for correct input
	if [[ -d $html ]]; then
    [  -z "$html" ] && htmlstat="$check_miss" || htmlstat="$check_ok"
	else
		printf $redbg"Wrong input format or choosen directory does not exist..."$reset
		html='/'
        sleep 3
        continue
	fi

  elif [ "$key1" = "4" ]; then
	echo -n "Enter backup directory (e.g. /var/www/html/backup): "
	read backup
	
	# Check for correct input
	if [[ -d $backup ]]; then
		[  -z "$backup" ] && backupstat="$check_miss" || backupstat="$check_ok"
	else
		printf $redbg"Wrong input format or choosen directory does not exist..."$reset
		backup='/'
        sleep 3
        continue
	fi

  elif [ "$key1" = "5" ]; then
	echo -n "Enter folder name (Leave empty, if you want to install to root directory): "
	read folder
	[  "$folder" ] && folderstat="$check_ok"

  elif [ "$key1" = "6" ]; then
	echo -n "Enter Database-Type (e.g. mysql, sqlite, etc.): "
	read dbtype
	[  -z "$dbtype" ] && dbtypestat="$check_miss" || dbtypestat="$check_ok"

  elif [ "$key1" = "7" ]; then
	echo -n "Enter Database-Host (e.g. localhost): "
	read dbhost
	[  -z "$dbhost" ] && dbhoststat="$check_miss" || dbhoststat="$check_ok"

  elif [ "$key1" = "s" ]; then
        if [ -z "$url1" ] || [ -z "$ncname" ] || [ -z "$html" ] || [ -z "$backup" ] || [ -z "$dbtype" ] || [ -z "$dbhost" ]; then
        	printf $redbg"One or more variables are undefined. Aborting..."$reset
        	sleep 3
        	continue
        else
        	echo "-----------------------------"
        break
        fi
  elif [ "$key1" = "q" ]; then
    exit
  fi
done

standardpath=$html/nextcloud
ncpath=$html/$folder

#################################
######   Setup Page 1 End   #####
#################################

# ask for SMTP-Setup
clear
printf $green"$header"$reset
echo ""
echo ""
   read -e -p "Do you want to setup SMTP (y/n)? " smtp

   if [ "$smtp" == "y" ] || [ "$smtp" == "Y" ]; then

#################################
######   SMTP-Setup Start   #####
#################################

clear
while true; do
  clear
printf $green"$header"$reset
echo ""
echo ""

  echo "--------------------------------------------------------------------------"
  echo "                    Setup SMTP"
  echo "------+------------+-----------------+------------------------------------"
  echo "  Nr. |   Status   |                 |    value"
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
  echo -en "Enter [1-8], [s] or [q]: ";read key2

  if [ "$key2" = "1" ]; then
  	echo -n "Enter Auth-Type (LOGIN, PLAIN, etc): "
	read smtpauth
    [  -z "$smtpauth" ] && smauthstat="$check_miss" || smauthstat="$check_ok"

  elif [ "$key2" = "2" ]; then
	echo -n "Enter SMTP-Host (e.g. yourdomain.com): "
	read smtphost

	# Check for correct input
	if [[ $smtphost =~ $regex ]]; then
		[  -z "$smtphost" ] && smhoststat="$check_miss" || smhoststat="$check_ok"
	else
		printf $redbg"Wrong input format. Enter a valid URL..."$reset
		smtphost="yourdomain.com"
        sleep 3
        continue
	fi

  elif [ "$key2" = "3" ]; then
	echo -n "Enter SMTP-Port (default :587): "
	read smtpport

	# Check for correct input
	if [[ "$smtpport" =~ ^[0-9]+$ ]]; then
		[  -z "$smtpport" ] && smportstat="$check_miss" || smportstat="$check_ok"
	else
		printf $redbg"Wrong input format. Only numbers are supported..."$reset
		smtpport='587'
        sleep 3
        continue
	fi

  elif [ "$key2" = "4" ]; then
	echo -n "Enter SMTP-Sendername (e.g. admin, info, etc): "
	read smtpname
	[  -z "$smtpname" ] && smnamestat="$check_miss" || smnamestat="$check_ok"

  elif [ "$key2" = "5" ]; then
	echo -n "Enter SMTP-password: "
	read smtppwd
	[  -z "$smtppwd" ] && smpwdstat="$check_miss" || smpwdstat="$check_ok"

  elif [ "$key2" = "6" ]; then
	echo -n "Enter SMTP-Security (tls, ssl, none): "
	read smtpsec

	# Check for correct input
	if [ "$smtpsec" = "tls" ] || [ "$smtpsec" = "ssl" ] || [ "$smtpsec" = "none" ]; then
		[  -z "$smtpsec" ] && smsecstat="$check_miss" || smsecstat="$check_ok"
	else
		printf $redbg"Wrong input format. Type ssl, tls or none..."$reset
		smtpsec='tls'
        sleep 3
        continue
	fi

  elif [ "$key2" = "7" ]; then
	echo -n "Is SMTP-Authentification required? (1 for yes - 0 for no): "
	read smtpauthreq

	# Check for correct input
	if [ "$smtpauthreq" = "0" ] || [ "$smtpauthreq" = "1" ]; then
		[  -z "$smtpauthreq" ] && smauthreqstat="$check_miss" || smauthreqstat="$check_ok"
	else
		printf $redbg"Wrong input format. Type 0 or 1..."$reset
		smtpauthreq='1'
        sleep 3
        continue
	fi

  elif [ "$key2" = "8" ]; then
	echo -n "Set SMTP sender Domain (e.g. yourdomain.com): "
	read smtpdomain

	# Check for correct input
	if [[ $smtpdomain =~ $regex ]]; then
		[  -z "$smtpdomain" ] && smtpdomainstat="$check_miss" || smtpdomainstat="$check_ok"
	else
		printf $redbg"Wrong input format. Enter a valid URL..."$reset
		smtpdomain="yourdomain.com"
        sleep 3
        continue
	fi

  elif [ "$key2" = "s" ]; then
        if [ -z "$smtpauth" ] || [ -z "$smtphost" ] || [ -z "$smtpport" ] || [ -z "$smtpname" ] || [ -z "$smtppwd" ] || [ -z "$smtpsec" ] || [ -z "$smtpauthreq" ] || [ -z "$smtpdomain" ]; then
        	printf $redbg"One or more variables are undefined. Aborting..."$reset
        	sleep 3
        	continue
        else
        	echo "-----------------------------"
        break
        fi
  elif [ "$key2" = "q" ]; then
    exit
  fi
done

else
	clear
printf $green"$header"$reset"\n"
echo ""
	printf "Skipping SMTP Setup..."
	sleep 2
fi
###############################
######   SMTP-Setup End   #####
###############################

###################################
######   Setup Page 2 Start   #####
###################################
clear
while true; do
  clear
printf $green"$header"$reset
echo ""
echo ""
  echo "--------------------------------------------------------------------------"
  echo "                    Setup			Page 2/3"
  echo "------+------------+------------------+------------------------------------"
  echo "  Nr. |   Status   |                  |    value"
  echo "------+------------+------------------+------------------------------------"
  printf "  1   |  $emailstat   |          E-Mail: | "$email"\n"
  printf "  2   |  $adusrstat   |  Admin Username: | "$adminuser"\n"
  echo ""
  printf "  3   |  $dbrootstat   |Database Root-PW: | "$database_root"\n"
  echo ""
  printf "  4   |  $htusrstat   |        WWW User: | "$htuser"\n"
  printf "  5   |  $htgrpstat   |       WWW Group: | "$htgroup"\n"
  printf "  6   |  $rootusrstat   |       root user: | "$rootuser"\n"
  echo "------+------------+------------------+------------------------------------"
  printf "Type [1-6] to change value or ${cyan}[s]${reset} to save and go to next page\n"
  printf "${red}[q]${reset} Quit\n"
  echo -en "Enter [1-6], [s] or [q]: ";read key3

  if [ "$key3" = "1" ]; then
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
	echo -n "Please enter desired admin username for Nextcloud: "
	read adminuser
	[  -z "$adminuser" ] && adusrstat="$check_miss" || adusrstat="$check_ok"

  elif [ "$key3" = "3" ]; then
	echo -n "Please enter password for database root account (won't be stored): "
	read database_root
	[  -z "$database_root" ] && dbrootstat="$check_miss" || dbrootstat="$check_ok"	

  elif [ "$key3" = "4" ]; then
	echo -n "Enter WWW-User (e.g. apache, apache2, etc.): "
	read htuser
	[  -z "$htuser" ] && htusrstat="$check_miss" || htusrstat="$check_ok"

  elif [ "$key3" = "5" ]; then
	echo -n "Enter WWW-Group (e.g. apache, www-data, etc.): "
	read htgroup
	[  -z "$htgroup" ] && htgrpstat="$check_miss" || htgrpstat="$check_ok"

  elif [ "$key3" = "6" ]; then
	echo -n "Enter root user (usually: root): "
	read rootuser
	[  -z "$rootuser" ] && rootusrstat="$check_miss" || rootusrstat="$check_ok"

  elif [ "$key3" = "s" ]; then
        if [ -z "$email" ] || [ -z "$htuser" ] || [ -z "$htgroup" ] || [ -z "$rootuser" ] || [ -z "$adminuser" ] || [ -z "$database_root" ]; then
        	printf $redbg"One or more variables are undefined. Aborting..."$reset
        	sleep 3
        	continue
        else
        	echo "-----------------------------"
        break
        fi
  elif [ "$key3" = "q" ]; then
    exit
  fi
done
#################################
######   Setup Page 2 End   #####
#################################

###################################
######   Setup Page 3 Start   #####
###################################
clear
while true; do
  clear
printf $green"$header"$reset
echo ""
echo ""
  echo "--------------------------------------------------------------------------"
  echo "                    Setup			Page 3/3"
  echo "------+------------+------------------+------------------------------------"
  echo "  Nr. |   Status   |                  |    value"
  echo "------+------------+------------------+------------------------------------"
  printf "  1   |  $dpnamestat   |    Display name: | "$displayname"\n"
  printf "  2   |  $rlchanstat   | Release Channel: | "$rlchannel"\n"
  printf "  3   |  $memstat   |        Memcache: | "$memcache"\n"
  printf "  4   |  $maintstat   |maintenance mode: | "$maintenance"\n"
  printf "  5   |  $singlestat   | singleuser mode: | "$singleuser"\n"
  echo "------+------------+------------------+------------------------------------"
  printf "Type [1-5] to change value or ${cyan}[s]${reset} to save and go to next page\n"
  printf "${red}[q]${reset} Quit\n"
  echo -en "Enter [1-5], [s] or [q]: ";read key3

  if [ "$key3" = "1" ]; then
  	echo -n "Allow users to change display name? (true/false): "
	read displayname

	# Check for correct input
	shopt -s nocasematch
	if [[ "$displayname" = "true" ]] || [[ "$displayname" = "false" ]]; then
		[  -z "$displayname" ] && dpnamestat="$check_miss" || dpnamestat="$check_ok"
	else
		printf $redbg"Wrong input format. Please type true/false..."$reset
		displayname='true'
        sleep 3
        continue
	fi
	shopt -u nocasematch

  elif [ "$key3" = "2" ]; then
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

  elif [ "$key3" = "3" ]; then
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

  elif [ "$key3" = "4" ]; then
	echo -n "Do you want to enable maintenance mode? (true/false): "
	read maintenance

	# Check for correct input
	shopt -s nocasematch
	if [[ "$maintenance" = "true" ]] || [[ "$maintenance" = "false" ]]; then
		[  -z "$maintenance" ] && maintstat="$check_miss" || maintstat="$check_ok"
	else
		printf $redbg"Wrong input format. Please type true/false..."$reset
		maintenance='false'
        sleep 3
        continue
	fi
	shopt -u nocasematch

  elif [ "$key3" = "5" ]; then
	echo -n "Do you want to enable single user mode? (true/false): "
	read singleuser

	# Check for correct input
	shopt -s nocasematch
	if [[ "$singleuser" = "true" ]] || [[ "$singleuser" = "false" ]]; then
		[  -z "$singleuser" ] && singlestat="$check_miss" || singlestat="$check_ok"
	else
		printf $redbg"Wrong input format. Please type true/false..."$reset
		singleuser='false'
        sleep 3
        continue
	fi
	shopt -u nocasematch

  elif [ "$key3" = "s" ]; then
        if [ -z "$displayname" ] || [ -z "$rlchannel" ] || [ -z "$memcache" ] || [ -z "$maintenance" ] || [ -z "$singleuser" ]; then
        	printf $redbg"One or more variables are undefined. Aborting..."$reset
			sleep 3
        	continue
        else
        	echo "-----------------------------"
        break
        fi
  elif [ "$key3" = "q" ]; then
    exit
  fi
done
#################################
######   Setup Page 3 End   #####
#################################

clear
printf $green"$header"$reset"\n"
echo ""

# Get latest nextcloud version
ncversion=$(curl -s -m 900 $ncrepo/ | tac | grep unknown.gif | sed 's/.*"nextcloud-\([^"]*\).zip.sha512".*/\1/;q')

# Check Nextcloud
echo "Checking latest released version on the Nextcloud download server and if it's possible to download..."
wget -q -T 10 -t 2 $ncrepo/nextcloud-$ncversion.tar.bz2 > /dev/null
if [ $? -eq 0 ]; then
	echo ""
    printf $ugreen"SUCCESS!\n"$reset
	rm -f nextcloud-$ncversion.tar.bz2
else
    echo ""
    printf $lightred"Nextcloud $ncversion doesn't exist.\n"$reset
    echo "Please check available versions here: $ncrepo"
    echo ""
    exit 1
fi

# Check if variables are set
if [ -z "$html" ] || [ -z "$backup" ] || [ -z "$ncpath" ] || [ -z "$ncname" ] || [ -z "$dbhost" ] || [ -z "$dbtype" ] || [ -z "$htuser" ] || [ -z "$htgroup" ] || [ -z "$rootuser" ] || [ -z "$standardpath" ] || [ -z "$ncrepo" ] || [ -z "$ncversion" ];
then

	echo ""
	printf $redbg"One or more variables are undefined. Aborting...\n"$reset
	echo ""
	sleep 1
	exit 0
else
# Install Warning
echo ""
printf "!! Warning !!\n"
echo ""
echo "Performing install in 5 seconds.."
echo ""
echo -ne '  |====>               |   (20%)\r'
sleep 1
echo -ne '  |=======>            |   (40%)\r'
sleep 1
echo -ne '  |===========>        |   (60%)\r'
sleep 1
echo -ne '  |===============>    |   (80%)\r'
sleep 1
echo -ne '  |===================>|   (100%)\r'
echo -ne '\n'
fi

####################
##  INSTALLATION  ##
####################

# Check if Nextcloud is already installed installed.

if [ -f "$ncpath/occ" ]; then
	chmod +x $ncpath/occ
	CURRENTVERSION=$(sudo -u $htuser php $ncpath/occ status | grep "versionstring" | awk '{print $3}')
	echo ""
    printf "Latest version is: ${ugreen}$ncversion ${reset}\n"
	echo ""
    printf $redbg"Nextcloud is already installed...\n"$reset
	echo ""
	echo "If your version isn't up to date make use of the Piet's Host ncupdate-script."
	echo ""
	sleep 2
    exit 0
else
	echo ""
    printf "Latest version is: ${ugreen}$ncversion${reset}\n"
	echo ""
    printf $green"No Nextcloud installation found! Installing continues...\n"$reset
	echo ""
	sleep 2
fi

# Download latest Nextcloud-Files
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

clear
printf $green"$header"$reset"\n"
echo ""
echo ""
####################
##  PASSWORD-GEN  ##
####################

	printf $yellow"Let's do some magic... Generating usernames and passwords..\n"$reset
	echo ""
	sleep 1

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
	exit 0
else

#################
##  DATABASE  ##
#################
printf $yellow"Creating Database...\n"$reset
echo ""
{
mysql -u root -p$database_root -e "CREATE DATABASE $dbname"
sleep 1
mysql -u root -p$database_root -e "USE $dbname"
sleep 1
mysql -u root -p$database_root -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpwd'"
sleep 1
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
'directory' => "$ncpath/data",
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
echo "Creating possible missing Directories"
echo ""
mkdir -p $ncpath/data
mkdir -p $ncpath/assets
mkdir -p $ncpath/updater

echo "chmod Files and Directories"
echo ""
find ${ncpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ncpath}/ -type d -print0 | xargs -0 chmod 0750

echo "chown Directories"
echo ""
chown -R ${rootuser}:${htgroup} ${ncpath}
chown -R ${htuser}:${htgroup} ${ncpath}/apps/
chown -R ${htuser}:${htgroup} ${ncpath}/assets/
chown -R ${htuser}:${htgroup} ${ncpath}/config/
chown -R ${htuser}:${htgroup} ${ncpath}/data/
chown -R ${htuser}:${htgroup} ${ncpath}/themes/
chown -R ${htuser}:${htgroup} ${ncpath}/updater/

chmod +x ${ncpath}/occ

echo "chmod/chown .htaccess"
echo ""
if [ -f ${ncpath}/.htaccess ]
 then
  chmod 0644 ${ncpath}/.htaccess
  chown ${rootuser}:${htgroup} ${ncpath}/.htaccess
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
curl $url
echo ""
printf $green"INDEXING COMPLETE\n"$reset
echo ""
sleep 1
printf $green"Finishing setup...\n"$reset
echo ""

#################
##  FINISHING  ##
#################

# enable 'no case match'
shopt -s nocasematch

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
		sudo -u ${htuser} php $ncpath/occ config:system:set updater.release.channel --value 'daily'
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

# disable 'no case match'	
shopt -u nocasematch

sudo -u ${htuser} php $ncpath/occ user:setting $adminuser settings email "$email"

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
echo ""
sleep 2

#################
##  ENDSCREEN  ##
#################
pwdtxt=$(pwd)

touch $pwdtxt/nextcloud_passwords.txt
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
} > $pwdtxt/nextcloud_passwords.txt

{
clear
printf $green"$header"$reset"\n"
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
echo "   (theses passwords are saved in $pwdtxt/nextcloud_passwords.txt)"
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

echo ""
} &>/dev/tty

###############
##  RESTART  ##
###############

# Restart server if desired
installed=yes
if [[ "$installed" == "yes" ]] ; then
    while true; do
        read -e -p "Do you want to restart your server now (y/n)? " rsn
        case $rsn in
            [Yy]* ) break;;
            [Nn]* ) exit;
        esac
    done
    shutdown -r now
fi
