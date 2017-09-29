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

function checkapps(){
[  -z "$contactsinstall" ] && contactsstat="$check_miss" || contactsstat="$check_ok"
[  -z "$calendarinstall" ] && calendarstat="$check_miss" || calendarstat="$check_ok"
[  -z "$mailinstall" ] && mailstat="$check_miss" || mailstat="$check_ok"
[  -z "$notesinstall" ] && notesstat="$check_miss" || notesstat="$check_ok"
[  -z "$tasksinstall" ] && tasksstat="$check_miss" || tasksstat="$check_ok"
[  -z "$galleryinstall" ] && gallerystat="$check_miss" || gallerystat="$check_ok"
[  -z "$impinstall" ] && impstat="$check_miss" || impstat="$check_ok"
}

function contactsinstall {
		# Download and install Contacts
		if [ -d $ncpath/apps/contacts ]
		then
			sleeping
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
			sleeping
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
			sleeping
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
			sleeping
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
			sleeping
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
			sleeping
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
			sleeping
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