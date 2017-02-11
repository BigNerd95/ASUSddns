#!/bin/sh

asus_request(){
    case $mode in
        "register")
            local path="ddns/register.jsp"
            ;;
        "update")
            local path="ddns/update.jsp"
            ;;
    esac
    local password=$(calculate_password)
    echo $(curl --write-out %{http_code} --silent --output /dev/null --user-agent "ez-update-3.0.11b5 unknown [] (by Angus Mackay)" --basic --user $user:$password "http://ns1.asuscomm.com/$path?hostname=$host&myip=$wanIP")
}

calculate_password(){
    local stripped_host=$(strip_dots_colons $host)
    local stripped_wanIP=$(strip_dots_colons $wanIP)
    echo $(echo -n "$stripped_host$stripped_wanIP" | openssl md5 -hmac "$key" 2>/dev/null | cut -d ' ' -f 2 | tr 'a-z' 'A-Z')
}

get_wan_ip(){
    echo $(curl --silent http://api.ipify.org/)
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

strip_dots_colons(){
    echo $(echo "$1" | tr -d .:)
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
    echo "Usage: mac wps host (register|update) (logger|console|silent)"
    echo
    echo "mac format: 00:11:22:33:44:55     (asus mac address) [to get it from nvram: nvram get et0macaddr]"
    echo "wps format: 12345678              (your wps code) [to get it from nvram: nvram get secret_code]"
    echo "host format: testestest           (your hostname without .asucomm.com)"
    echo
    echo "Program output:"
    echo "logger   -->  /var/log/messges"
    echo "console  -->  console"
    echo "silent   -->  mute output"
    echo
    echo "example to register and update testestest.asuscomm.com:"
    echo "$0 00:11:22:33:44:55 12345678 testestest register console"
    echo "$0 00:11:22:33:44:55 12345678 testestest update logger"
    echo
    echo "Launch 'register' the first time to register the new domain with your mac address."
    echo "Launch 'update' each 5 minutes (eg: with cron jobs) to keep dns updated."
    echo
    echo "ASUSddns script by BigNerd95 (https://github.com/BigNerd95/ASUSddns)"
}

if [ $# -eq 5 ]
then
    user=$(strip_dots_colons $1)
    key=$2
    host="$3.asuscomm.com"
    mode=$4
    output=$5

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
