# ASUSddns slim  
Some firmware may not satisfy the dependences of the complete version  
This is a slim version to allow anyone to use this feature

### PORS
- doesn't require curl  
- doesn't require openssl 
- doesn't require cron jobs
### CONS
- may stop working in the future [see explanation](#explanation)
- you must provide the base64 of your Asus mac address

# Usage
`./ASUSddns_slim.sh mac_b64 host (register|update) (logger|console|silent)`

#### mac_b64
Mac address of wan interface, it is used as username.  
It must be an asus mac address or the request will fails.  
To get it, launch:  
`nvram get et0macaddr`  

Because we are not using curl we need to encode the username in base64  
If your mac address is 00:11:22:33:44:55 you must do the following operations:  
1) `00:11:22:33:44:55` wan mac address
2) `001122334455`  remove colons
3) `001122334455:`  add colon at the end
4) `base64(001122334455:)`  encode in base64 this result (you can use https://www.base64encode.org/)
5) `MDAxMTIyMzM0NDU1Og==`  the encoded result [this is mac_b64]

#### host
Host is the hostname you want without .asuscomm.com part.  
For example if you want testestest.asucomm.com,  
you only have to write `testestest`.

# Examples
#### Register a new dns (testestest.asuscomm.com)
`./ASUSddns_slim.sh MDAxMTIyMzM0NDU1Og== testestest register console`

#### Update dns
`./ASUSddns_slim.sh MDAxMTIyMzM0NDU1Og== testestest update logger`

#### Run update each 5 minutes

```bash
while true
do
  /path/ASUSddns_slim.sh MDAxMTIyMzM0NDU1Og== testestest update logger
  sleep 300
done
```
Create a bash file containing the previous code and launch it in background  
`./update_loop.sh &`

# Explanation

### CURL
Http requests are reimplemented using netcat

### Openssl 
The Asus server is not checking the password at all and the request is accepted also with a blank password  
So we don't need to calculate the hmac md5 with the mac address, ip address and wps code  
But Asus may fix the server, so this script may stop working in the future  
