#!/bin/sh

asus_request(){
    case $mode in
        "register")
            local path="/ddns/register.jsp"
            ;;
        "update")
            local path="/ddns/update.jsp"
            ;;
    esac
    echo $(curl --write-out %{http_code} --silent --output /dev/null --user-agent "ez-update-3.0.11b5 unknown [] (by Angus Mackay)" --basic --user $user:$password http://ns1.asuscomm.com/$path\?hostname=$host\&myip=$wanIP)
}

get_wan_ip(){
    echo $(curl --silent http://api.ipify.org/)
    #echo $(ifconfig -a $(nvram get pppoe_ifname) 2>/dev/null | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)
}

get_dns_ip(){
    echo $(nslookup $1 ns1.asuscomm.com 2>/dev/null | grep Address | tail -n 1 | cut -d ' ' -f 3)
}

calculate_password(){
    local stripped_host=$(remove_dots_colon $host)
    local stripped_wanIP=$(remove_dots_colon $wanIP)
    echo $(echo -n "$stripped_host$stripped_wanIP" | openssl md5 -hmac "$key" 2>/dev/null | cut -d ' ' -f 2 | tr 'a-z' 'A-Z')
}

remove_dots_colon(){
    echo $(echo "$1" | sed -r 's/[:]+//g' | sed -r 's/[.]+//g')
}

log(){
    case $output in
        "logger")
            logger -t "ASUSddns" "$1"
            ;;
        "console")
            echo "$1" >&2
            ;;
    esac
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
        203 )
            echo "$log_mode failed."
            ;;
        220 )
            echo "$log_mode same domain success."
            ;;
        230 )
            echo "$log_mode new domain success."
            ;;
        233 )
            echo "$log_mode failed."
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

execute(){
    case $mode in
        "register")
            ;;
        "update")
            local dnsIP=$(get_dns_ip $host)
            if [ $wanIP = $dnsIP ]
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

    return_code=$(asus_request)
    res=$(code_to_string $return_code)
    log "$res"
}

main(){
    wanIP=$(get_wan_ip)
    if [ -n "${wanIP}" ]
    then
        user=$(remove_dots_colon $1)
        key=$2
        host="$3.asuscomm.com"
        mode=$4
        output=$5
        password=$(calculate_password $host $wanIP $key)
        
        execute
    else
        log "No internet connection, can\'t control."
    fi
}

if [ $# -eq 5 ]
then
   main $1 $2 $3 $4 $5
else
    echo "Usage: mac key host (update|register) (log|echo|silent)"
    echo
    echo "mac format: 00:11:22:33:44:55     (asus mac address) [to get it from nvram: nvram get et0macaddr]"
    echo "key format: 12345678              (your wps code) [to get it from nvram: nvram get secret_code]"
    echo "host format: testetstest          (without .asucomm.com)"
    echo
    echo "Program output:"
    echo "logger    --> /var/log/messges"
    echo "console   --> console"
    echo "silent    --> mute output"
    echo
    echo "example to register and update testetstest.asuscomm.com:"
    echo "$0 00:11:22:33:44:55 12345678 testetstest register console"
    echo "$0 00:11:22:33:44:55 12345678 testetstest update logger"
    echo
    echo "Launch 'register' the first time to register the new domain with your mac address."
    echo "Launch 'update' each 10 minutes (eg: with cron jobs) to keep dns updated."
    echo
    echo "ASUSddns script by BigNerd95 (https://github.com/BigNerd95/ASUSddns)"
fi
