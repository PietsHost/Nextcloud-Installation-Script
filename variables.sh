#!/bin/bash
#
## Piet's Host ## - ©2017, https://piets-host.de
#
# Edit the following Lines of Code
# If you don't want to use these variables,
# consider to start the Script with "-c" flag
# instead and use the default.json config-file.

url1="http://example.com"
ncname="my_nextcloud"
dbhost="localhost"
dbtype="mysql"
database_root="MyS€cretP@sS!" # Database root password
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
depend="true"
overwrite="true"
isconfig="false"
config_to_read="default.json"
cron="false"
