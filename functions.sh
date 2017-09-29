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

# Read JSON config file
function jsonconfig {
echo "Reading JSON config $config_to_read ..."
chmod 0644 $config_to_read
sleep 0.5
# General - SQL
dbhost=$(json -f "$config_to_read" general.sql.dbhost)
dbruser=$(json -f "$config_to_read" general.sql.dbruser)
dbtype=$(json -f "$config_to_read" general.sql.dbtype)
database_root=$(json -f "$config_to_read" general.sql.database_root)

# General - HTML
url1=$(json -f "$config_to_read" general.html.url1)
ncname=$(json -f "$config_to_read" general.html.ncname)
html=$(json -f "$config_to_read" general.html.html)
folder=$(json -f "$config_to_read" general.html.folder)

# General - Perm
rootuser=$(json -f "$config_to_read" general.perm.rootuser)
htuser=$(json -f "$config_to_read" general.perm.htuser)
htgroup=$(json -f "$config_to_read" general.perm.htgroup)

# General - Other
depend=$(json -f "$config_to_read" general.other.depend)
rebootsrv=$(json -f "$config_to_read" general.other.rebootsrv)
overwrite=$(json -f "$config_to_read" general.other.overwrite)
adminuser=$(json -f "$config_to_read" general.other.adminuser)
smtp=$(json -f "$config_to_read" general.other.smtp)
appsinstall=$(json -f "$config_to_read" general.other.appsinstall)
version=$(json -f "$config_to_read" general.other.version)
cron=$(json -f "$config_to_read" general.other.cron)
icon=$(json -f "$config_to_read" general.other.icon)

# General - E-mail
email=$(json -f "$config_to_read" general.mail.email)
smtpauth=$(json -f "$config_to_read" general.mail.smtpauth)
smtpport=$(json -f "$config_to_read" general.mail.smtpport)
smtpname=$(json -f "$config_to_read" general.mail.smtpname)
smtpsec=$(json -f "$config_to_read" general.mail.smtpsec)
smtppwd=$(json -f "$config_to_read" general.mail.smtppwd)
smtpauthreq=$(json -f "$config_to_read" general.mail.smtpauthreq)
smtphost=$(json -f "$config_to_read" general.mail.smtphost)
smtpdomain=$(json -f "$config_to_read" general.mail.smtpdomain)

# Config - Custom
displayname=$(json -f "$config_to_read" config.custom.displayname)
rlchannel=$(json -f "$config_to_read" config.custom.rlchannel)
memcache=$(json -f "$config_to_read" config.custom.memcache)
maintenance=$(json -f "$config_to_read" config.custom.maintenance)
singleuser=$(json -f "$config_to_read" config.custom.singleuser)
skeleton=$(json -f "$config_to_read" config.custom.skeleton)
default_language=$(json -f "$config_to_read" config.custom.default_language)
enable_avatars=$(json -f "$config_to_read" config.custom.enable_avatars)
rewritebase=$(json -f "$config_to_read" config.custom.rewritebase)

# Config - Apps
contactsinstall=$(json -f "$config_to_read" apps.integrated.contactsinstall)
calendarinstall=$(json -f "$config_to_read" apps.integrated.calendarinstall)
mailinstall=$(json -f "$config_to_read" apps.integrated.mailinstall)
notesinstall=$(json -f "$config_to_read" apps.integrated.notesinstall)
tasksinstall=$(json -f "$config_to_read" apps.integrated.tasksinstall)
galleryinstall=$(json -f "$config_to_read" apps.integrated.galleryinstall)

impinstall=$(json -f "$config_to_read" apps.3rdparty.impinstall)
echo ""
}

function sleeping {
if [[ "$isconfig" = "true" ]]; then
	sleep 1
else
	sleep 0.2
fi
}
function sleeping2 {
if [[ "$isconfig" = "true" ]]; then
	sleep 2
else
	sleep 0.2
fi
}
function sleeping3 {
if [[ "$isconfig" = "true" ]]; then
	sleep 2
else
	sleep 1.2
fi
}
function abort {
	echo ""
	stty echo
	exit 0
}
function plesk {
dbruser='admin'
database_root="`cat /etc/psa/.psa.shadow`"
htgroup='psacln'
perm='plesk'
}
function anykey {
echo ""
read -n1 -r -p " Press any key to continue..." key
			if [ "$key" = '' ]; then
				echo ""
				return
			fi
}

function spinner {
pid=$!
i=0
sp="/-\|"
while kill -0 $pid 2>/dev/null
	do
	i=$(( (i+1) %4 ))
	printf "\r[${sp:$i:1}]"
	sleep .1
done
echo ""
}

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
[  -z "$cron" ] && cronstat="$check_miss" || cronstat="$check_ok"
[  -z "$icon" ] && iconstat="$check_miss" || iconstat="$check_ok"
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
		sleeping
	elif [ "$smtpauthreq" = "1" ]; then
		smtpauthreq='0'
		smauthreqstat="$check_ok"
		printf $red"SMTP-Authentification disabled\n"$reset
		sleeping
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
  abort
  fi
done
}

function installapps(){

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
		sleeping
	elif [ "$contactsinstall" = "false" ]; then
		contactsinstall='true'
		contactsstat="$check_ok"
		printf $green"contacs installation turned on\n"$reset
		sleeping
	fi

  elif [ "$key5" = "2" ]; then
	if [ "$calendarinstall" = "true" ]; then
		calendarinstall='false'
		calendarstat="$check_ok"
		printf $red"calendar installation turned off\n"$reset
		sleeping
	elif [ "$calendarinstall" = "false" ]; then
		calendarinstall='true'
		calendarstat="$check_ok"
		printf $green"calendar installation turned on\n"$reset
		sleeping
	fi

  elif [ "$key5" = "3" ]; then
	if [ "$mailinstall" = "true" ]; then
		mailinstall='false'
		mailstat="$check_ok"
		printf $red"mail installation turned off\n"$reset
		sleeping
	elif [ "$mailinstall" = "false" ]; then
		mailinstall='true'
		mailstat="$check_ok"
		printf $green"mail installation turned on\n"$reset
		sleeping
	fi

  elif [ "$key5" = "4" ]; then
	if [ "$notesinstall" = "true" ]; then
		notesinstall='false'
		notesstat="$check_ok"
		printf $red"notes installation turned off\n"$reset
		sleeping
	elif [ "$notesinstall" = "false" ]; then
		notesinstall='true'
		notesstat="$check_ok"
		printf $green"notes installation turned on\n"$reset
		sleeping
	fi

  elif [ "$key5" = "5" ]; then
	if [ "$tasksinstall" = "true" ]; then
		tasksinstall='false'
		tasksstat="$check_ok"
		printf $red"tasks installation turned off\n"$reset
		sleeping
	elif [ "$tasksinstall" = "false" ]; then
		tasksinstall='true'
		tasksstat="$check_ok"
		printf $green"tasks installation turned on\n"$reset
		sleeping
	fi

  elif [ "$key5" = "6" ]; then
	if [ "$galleryinstall" = "true" ]; then
		galleryinstall='false'
		gallerystat="$check_ok"
		printf $red"gallery installation turned off\n"$reset
		sleeping
	elif [ "$galleryinstall" = "false" ]; then
		galleryinstall='true'
		gallerystat="$check_ok"
		printf $green"gallery installation turned on\n"$reset
		sleeping
	fi

  elif [ "$key5" = "7" ]; then
	if [ "$impinstall" = "true" ]; then
		impinstall='false'
		impstat="$check_ok"
		printf $red"impersonate installation turned off\n"$reset
		sleeping
	elif [ "$impinstall" = "false" ]; then
		impinstall='true'
		impstat="$check_ok"
		printf $green"impersonate installation turned on\n"$reset
		sleeping
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
	abort
  fi
done
}

show_help() {
cat << EOF

 Usage: ${0##*/} [-v VERSION] [-n NAME]...
 You can specify some variables before script run.
 E.g. you can set the Nextcloud version or the
 MySQL root password. If no option is set, the
 script will use default variables and you
 can set them during script run (you will
 be asked) :-)

 -h --help	display this help and exit
 -v --version	specify Nextcloud Version (e.g. 10.0.0)
 -p --password	sets the MySQL root password. Type -p "P@s§"
 -r --root	sets the MySQL root user
 -m --mysqlhost	sets the MySQL Host
 -n --name	sets the Nextcloud name, used for Database
 -u --url	sets the URL for Nextcloud installation
 -d --directory	sets the full installation path
 -f --folder 	sets the desired folder (example.com/folder). May be empty
 -s --smtp	setup SMTP during script run (Type -s "y" or -s "n")
 -a --apps 	setup additionals apps during run (Type -a "y" or -a "n")
 -c --config	path to JSON config file
 --cron  enable automatic cronjob (Type --cron "true")
 -i --icon specify path of you own favicon.ico file

EOF
}

function readusers {
rootuser=$(json -f "$config_to_read" general.perm.rootuser)
dbruser=$(json -f "$config_to_read" general.sql.dbruser)
htuser=$(json -f "$config_to_read" general.perm.htuser)
htgroup=$(json -f "$config_to_read" general.perm.htgroup)
}

# function check MySQL Login
function mysqlcheck () {
if [[ "dbhost" = "localhost" ]]; then
	mysql -u $dbruser -p$database_root  -e ";"
else
	mysql -u $dbruser -p$database_root -h $dbhost -e ";"
fi
} &> /dev/null

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