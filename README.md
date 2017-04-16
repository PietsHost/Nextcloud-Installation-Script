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

**Older Version**<br />
This script supports the installation of older Nextcloud-Version.<br />
Keep in mind, that older version may be vulnerable due to security gaps

If you want to install v9.0.53 for example, use:
```
./nc_install.sh -v 9.0.53
```

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
