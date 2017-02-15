# ASUSddns
Asus ddns update and registration script for DD-WRT and others platforms.  
This script allows you to use the Asus ddns service on Asus router with a modified firmware like DD-WRT or OpenWRT.  
You can enable jffs on your router or save the script on a usb drive attached to the router.  

# Installation

`curl https://raw.githubusercontent.com/BigNerd95/ASUSddns/master/ASUSddns.sh -O -k`  
`chmod 777 ASUSddns.sh`  

# Usage
`./ASUSddns.sh mac wps host (register|update) (logger|console|silent)`  

#### mac
Mac address of wan interface, it is used as username.  
It must be an asus mac address or the request will fails.  
To get it, launch:  
`nvram get et0macaddr`  

#### wps
Wps pin code.  
To get it, launch:  
`nvram get secret_code`  

#### host
Host is the hostname you want without .asuscomm.com part.  
For example if you want testestest.asucomm.com,  
you only have to write `testestest`.  

#### action
- register  
  This action is needed only once, to register a new hostname with your Asus mac address.
- update  
  This action is needed all the times you need to update the dns with your new wan ip.


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

#### Run update each 5 minutes
`*/5 * * * * root /path/ASUSddns.sh 00:11:22:33:44:55 12345678 testestest update logger`

(DD-WRT: add this line in Administration -> Management -> Cron)

# Dependences
Openssl, curl
