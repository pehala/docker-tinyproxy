#!/bin/bash

###############################################################################
# Name:         run.sh
# Author:       Daniel Middleton <daniel-middleton.com>
# Description:  Used as ENTRYPOINT from Tinyproxy's Dockerfile
# Usage:        See displayUsage function
###############################################################################

# Global vars
PROG_NAME='DockerTinyproxy'
PROXY_CONF='/etc/tinyproxy/tinyproxy/tinyproxy.conf'
#PROXY_CONF='/var/tinyproxy.conf'
TAIL_LOG='/var/log/tinyproxy/tinyproxy.log'

# Usage: screenOut STATUS message
screenOut() {
    timestamp=$(date +"%H:%M:%S")
    
    if [ "$#" -ne 2 ]; then
        status='INFO'
        message="$1"
    else
        status="$1"
        message="$2"
    fi

    echo -e "[$PROG_NAME][$status][$timestamp]: $message"
}

# Usage: checkStatus $? "Error message" "Success message"
checkStatus() {
    case $1 in
        0)
            screenOut "SUCCESS" "$3"
            ;;
        1)
            screenOut "ERROR" "$2 - Exiting..."
            exit 1
            ;;
        *)
            screenOut "ERROR" "Unrecognised return code."
            ;;
    esac
}

displayUsage() {
    echo
    echo '  Usage:'
    echo "      docker run -d --name='tinyproxy' -p <Host_Port>:8888 pehala/tinyproxy:latest"
    echo
    echo "      - Set <Host_Port> to the port you wish the proxy to be accessible from."
    echo "      - Set env variable RULES to 'ANY' to allow unrestricted proxy access, or one or more spece seperated IP/CIDR addresses for tighter security."
    echo
    echo "      Examples:"
    echo "          docker run -d --name='tinyproxy' -p 6666:8888 pehala/tinyproxy:latest ANY"
    echo "          docker run -d --name='tinyproxy' -p 7777:8888 pehala/tinyproxy:latest 87.115.60.124"
    echo "          docker run -d --name='tinyproxy' -p 8888:8888 pehala/tinyproxy:latest 10.103.0.100/24 192.168.1.22/16"
    echo
}

parseAccessRules() {
    list=''
    for ARG in $@; do
        line="Allow\t$ARG\n"
        list+=$line
    done
    echo "$list" | sed 's/.\{2\}$//'
}

setMiscConfig() {
    sed -i -e"s,^MinSpareServers ,MinSpareServers\t1 ," $PROXY_CONF
    checkStatus $? "Set MinSpareServers - Could not edit $PROXY_CONF" \
                   "Set MinSpareServers - Edited $PROXY_CONF successfully."

    sed -i -e"s,^MaxSpareServers ,MaxSpareServers\t1 ," $PROXY_CONF
    checkStatus $? "Set MinSpareServers - Could not edit $PROXY_CONF" \
                   "Set MinSpareServers - Edited $PROXY_CONF successfully."
    
    sed -i -e"s,^StartServers ,StartServers\t1 ," $PROXY_CONF
    checkStatus $? "Set MinSpareServers - Could not edit $PROXY_CONF" \
                   "Set MinSpareServers - Edited $PROXY_CONF successfully."
}

setAccess() {
    if [[ "$1" == *ANY* ]]; then
        sed -i -e"s/^Allow /#Allow /" $PROXY_CONF
        checkStatus $? "Allowing ANY - Could not edit $PROXY_CONF" \
                       "Allowed ANY - Edited $PROXY_CONF successfully."
    else
        sed -i "s,^Allow 127.0.0.1,$1," $PROXY_CONF
        checkStatus $? "Allowing IPs - Could not edit $PROXY_CONF" \
                       "Allowed IPs - Edited $PROXY_CONF successfully."
    fi
}

allowSSL() {
    sed -i -e"s,#ConnectPort,ConnectPort ," $PROXY_CONF
    checkStatus $? "Allow SSL ports - Could not edit $PROXY_CONF" \
                   "Allow SSL ports - Edited $PROXY_CONF successfully."
}

startService() {
    screenOut "Starting Tinyproxy service..."
    /usr/bin/tinyproxy -d
    checkStatus $? "Could not start Tinyproxy service." \
                   "Tinyproxy service started successfully."
}

# Check Rules
if [[ -z "${RULES}" ]]; then
    screenOut "RULES env variable is not set, permitting unrestricted proxy access"
    RULES="ALL"
fi
# Start script
echo && screenOut "$PROG_NAME script started..."
# Parse ACL from args
export rawRules="$RULES" && parsedRules=$(parseAccessRules $rawRules) && unset rawRules
# Set ACL in Tinyproxy config

allowSSL

setAccess $parsedRules
# Start Tinyproxy
startService

screenOut "$PROG_NAME script ended." && echo
exit 0
