# Nextcloud Installation Script
Easy automatic CLI-Installation of Nextcloud


This script features an automatic installation of Nextcloud via CLI.<br /><br />
The script will check if you've already installed a Nextcloud version and if it's the latest release-version (e.g. 11.0.2).<br />

You decide, how you want to install Nextcloud on your server. For example you can set the target directory, SMTP-Credentials,<br />
admin-Username and much more!

Database-Name, Database-password and Admin-password will be generated automatically - due to security reasons.

Now let the script do it's work. 

That's it! Once it's done, visit your website and enjoy Nextcloud!

# Usage
Download or clone this repository.

After that, set +x to the script and run it:
```
chmod +x ./nc_install.sh
./nc_install.sh
```

## Usage of script arguments

 You can specify some variables before script run.<br />
 E.g. you can set the Nextcloud version or the <br />
 MySQL root password. If no option is set, the<br />
 script will use default variables.<br />

	-h --help	display this help and exit
	-v --version	specify Nextcloud Version (e.g. 10.0.0)
	-p --password	sets the MySQL root password. Type -d "P@s§"
	-n --name	sets the Nextcloud name, used for Database
	-u --url	sets the URL for Nextcloud installation
	-d --directory	sets the full installation path
	-f --folder sets the desired folder (example.com/folder). May be empty
	-s --smtp	setup SMTP during script run (no argument required)
	-a --apps setup additionals apps during run (no argument required)

If you want to install v9.0.53 for example, use:<br />
`./nc_install.sh -v 9.0.53` or `./nc_install.sh --version 9.0.53`

## Notes
* Tested on CentOS 6.8 & 7.3
* Tested on openSUSE Leap 42.1
* Tested on Ubuntu 12.04, 14.04, 16.04
* Tested on Fedora 23 & 25
* Tested on Debian 7 & 8

I'm sure it will work on every Linux System, even if I haven't tested it yet :)

## Requirements
This script requires the following packages: `pv bzip2 rsync php-process bc`<br />
The packages will be installed automatically when you run the script.
