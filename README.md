# ASUSddns
Asus ddns update and registration script for DD-WRT and others platforms.

This script allows you to use the Asus ddns service on Asus router with a modified firmware like DD-WRT or OpenWRT.

You can enable jffs on your router or save the script on a usb drive attached to the router.


# Usage
`./ASUSddns.sh mac key host (register|update) (logger|console|silent)`

#### mac
Mac address of wan interface, it is used as username.

It must be an asus mac address or the request will fails.

To get the mac address simply run:

`nvram get et0macaddr`


#### key
Key is the wps code.

To get the wps run:

`nvram get secret_code`


#### host
Host is the hostname you want without .asuscomm.com part.

For example if you want testestest.asucomm.com,

you have to write only `testestest`.


#### action
- register 

  This action is needed only once, to register a new hostname with your mac address. 
- update

  This action is needed all times you need to update the dns with your new ip.


#### output
- logger

  Prints script output on the system log.
  (On ddwrt: /var/log/messages)
- console

  Prints script output on stderr.
- silent

  Disable script output.
  
# Examples
#### Register a new dns (testestest.asuscomm.com)
`./ASUSddns.sh 00:11:22:33:44:55 12345678 testestest register console`

#### Update dns
`./ASUSddns.sh 00:11:22:33:44:55 12345678 testestest update logger`

#### Run update each 10 minutes
`*/10 * * * * root /path/ASUSddns.sh 00:11:22:33:44:55 12345678 testestest update logger`

(DD-WRT: add this line in Administration -> Management -> Cron)

# Dependences
Openssl, curl
