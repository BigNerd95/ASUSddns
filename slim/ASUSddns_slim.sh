#!/bin/sh

# This is the slim version of ASUSddns script
# PROS:
#   - doesn't require curl (http requests implemented with netcat)
#   - doesn't require openssl (Asus server is not checking the password, so we don't need to calculate it)
# CONS:
#   - may stop working in the future if Asus fixes its server
#   - you must provide the base64 of your Asus mac address (see the usage)

##############################################################################################
# If this script stop working use the complete version https://github.com/BigNerd95/ASUSddns #
##############################################################################################

asus_request(){
    case $mode in
        "register")
            local path="ddns/register.jsp"
            ;;
        "update")
            local path="ddns/update.jsp"
            ;;
    esac

    echo $(echo -e -n "GET /$path?hostname=$host&myip=$wanIP HTTP/1.1\r\nHost: ns1.asuscomm.com\r\nAuthorization: Basic $user_base64\r\n\r\n" | nc -w 5 ns1.asuscomm.com 80 | head -1 | cut -d ' ' -f 2)
}

get_wan_ip(){
    echo $(echo -e -n "GET / HTTP/1.1\r\nHost: api.ipify.org\r\n\r\n" | nc -w 5 api.ipify.org 80 | tail -1)
    #echo $(ifconfig -a $(nvram get pppoe_ifname) 2>/dev/null | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)
}

is_dns_updated(){
    local dns_resolution=$(nslookup $host ns1.asuscomm.com 2>/dev/null)
    # check if wanIP is in nslookup result
    for token in $dns_resolution
    do
        if [ $token = $wanIP ]
        then
            return 0 # true
        fi
    done
    return 1 # false
}

code_to_string(){
    case $mode in
        "register")
            local log_mode="Registration"
            ;;
        "update")
            local log_mode="Update"
            ;;
    esac

    case $1 in
        200 )
            echo "$log_mode success."
            ;;
        203 | 233 )
            echo "$log_mode failed."
            ;;
        220 )
            echo "$log_mode same domain success."
            ;;
        230 )
            echo "$log_mode new domain success."
            ;;
        297 )
            echo "Invalid hostname."
            ;;
        298 )
            echo "Invalid domain name."
            ;;
        299 )
            echo "Invalid IP format."
            ;;
        401 )
            echo "Authentication failure."
            ;;
        407 )
            echo "Proxy authentication Required."
            ;;
        * )
            echo "Unknown result code. ($1)"
            ;;
    esac
}

log(){
    case $output in
        "logger")
            logger -t "ASUSddns" "$1"
            ;;
        "silent")
            ;;
        *)
            echo "$1" >&2
            ;;
    esac
}

main(){
    case $mode in
        "register")
            ;;
        "update")
            if is_dns_updated
            then
                log "Domain already updated."
                return
            fi
            ;;
        *)
            log "Unknown action! Allowed action: register or update"
            return
            ;;
    esac

    local return_code=$(asus_request)
    local res=$(code_to_string $return_code)
    log "$res"
}

usage(){
    echo "Usage: mac_b64 host (register|update) (logger|console|silent)"
    echo
    echo "mac_b64 format: MDAxMTIyMzM0NDU1Og==    (See 'Caltulate mac_b64' below) [to get it from nvram: nvram get et0macaddr]"
    echo "host    format: testestest              (your hostname without .asucomm.com)"
    echo
    echo "Program output:"
    echo "logger   -->  /var/log/messges"
    echo "console  -->  console"
    echo "silent   -->  mute output"
    echo
    echo "Caltulate mac_b64"
    echo "If your mac address is 00:11:22:33:44:55 you must do the following operations:"
    echo "00:11:22:33:44:55  -->  001122334455  -->  001122334455:  -->  base64('001122334455:')  -->  MDAxMTIyMzM0NDU1Og=="
    echo "(You can use https://www.base64encode.org/ to encode it)"
    echo
    echo "Example to register and update testestest.asuscomm.com:"
    echo "$0 MDAxMTIyMzM0NDU1Og== testestest register console"
    echo "$0 MDAxMTIyMzM0NDU1Og== testestest update logger"
    echo
    echo "Launch 'register' the first time to register the new domain with your mac address."
    echo "Launch 'update' each 5 minutes (eg: with cron jobs or a bash script with a while loop and a sleep 300) to keep dns updated."
    echo
    echo "ASUSddns slim script by BigNerd95 (https://github.com/BigNerd95/ASUSddns/tree/master/slim)"
}

if [ $# -eq 4 ]
then
    user_base64=$1
    host="$2.asuscomm.com"
    mode=$3
    output=$4

    wanIP=$(get_wan_ip)
    if [ -n "${wanIP}" ]
    then
        main
    else
        log "No internet connection, cannot check."
    fi
else
    usage
fi
