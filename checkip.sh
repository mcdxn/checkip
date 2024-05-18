#!/bin/bash
# Last Updated: August 23, 2023

declare -r MY_VERSION='3'
declare -r DNS_CLOUD_SERVICE='CloudFlare'

# CF_ stand for CloudFlare
declare -r CF_GLOBAL_API_KEY='YOUR_GLOBAL_API_KEY'
declare -r CF_API_TOKEN='YOUR_API_TOKEN'
declare -r CF_EMAIL='YOUR_EMAIL@ADDRESS'

declare -r CF_DOMAIN_NAME_1='YOUR_DOMAIN.com'
declare -r CF_ZONE_ID_1='YOUR_ZONE_ID'
declare -r CF_DNS_RECORD_ID_1='THE_DNS_RECORD_ID'

declare -r NOTIFY_EMAIL_ADDRESS='YOUR_EMAIL@ADDRESS.com'
declare -r MY_LOG=/var/log/checkip.log




function check_ip_address(){

if [ ! -f $MY_LOG ] ; then
printf "No log found: %s \n" $MY_LOG
printf "Creating log: %s \n\n" $MY_LOG
touch $MY_LOG
fi

if [ -z $(cat $MY_LOG) ] ; then
printf "000.000.000.000" > $MY_LOG
fi

declare -a IP_SITES=("myexternalip.com/raw" "ifconfig.me" "ipecho.net/plain" "icanhazip.com")

# Make sure to update the number after the modulos operator in the INDEX 
# calculation after adding or removing sites in IP_SITES.
# Currently, the number after the modulos operator is 4 because 
# there are four items in the IP_SITES array.
declare -r INDEX=$(($RANDOM%4))

declare -r SITE=${IP_SITES[$(($INDEX))]}

printf "\n==== CHECKIP v%s =================================\n\n" $MY_VERSION
printf "Checking public ip address using: %s\n\n" $SITE

declare previousIP=$(cat $MY_LOG)
declare currentIP=$(curl -s $SITE | tr -d '\n')

printf "Old IP: %s \n" $previousIP
printf "New IP: %s \n" $currentIP

if [ "$currentIP" != "$previousIP" ] ; then

declare -r MY_JSON_DATA_1=$(printf '{"type":"A","name":"%s","content":"%s","proxied":true}' $CF_DOMAIN_NAME_1 $currentIP)

printf "\n\n"

curl --request PUT \
    --url "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID_1/dns_records/$CF_DNS_RECORD_ID_1" \
    --header "X-Auth-Email: $CF_EMAIL" \
    --header "X-Auth-Key: $CF_GLOBAL_API_KEY" \
    --header "Authorization: Bearer $CF_API_TOKEN" \
    --header "Content-Type: application/json" \
    --data $MY_JSON_DATA_1

printf "\n\n"
printf "%s %s" $currentIP "$(date)" | mail -s "ip update" -a "From: Server Robot <SOME_EMAIL@ADDRESS.com>" $NOTIFY_EMAIL_ADDRESS
printf "%s" $currentIP > $MY_LOG
printf "\n\n"
printf "RESULTS:\n"
printf "    - Your dynamic ip address has changed.\n"
printf "    - Emailed %s notification of new ip address.\n" $NOTIFY_EMAIL_ADDRESS
printf "    - Updated %s DNS record.\n\n" $DNS_CLOUD_SERVICE


else

printf "\nRESULTS:\n"
printf "    - Your dynamic ip address has NOT changed.\n"

fi

printf "\n\n=================================================\n"

}

# Execute function
check_ip_address
