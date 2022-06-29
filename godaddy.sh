#!/usr/bin/env bash

# domain api: https://developer.godaddy.com/doc/endpoint/domains

# create api key and secret
. godday_api_Key.sh
accept="application/json"
Content="application/json"
Authorization=" sso-key $API_KEY:$API_SECRET"
echo $Authorization

domain_prompt(){
    read -p "please input domain: " domain
}

record_type_prompt(){
    read -p "please input record_type: " record_type
}

record_prompt(){
    read -p "please input record: " record
}

domain_ip_prompt(){
    read -p "please input domain_ip: " domain_ip
}


# get public ip from ipinfo.io
public_ip="$(curl --silent ipinfo.io/ip)"

# get current record
current_record="$(dig @8.8.8.8 +short $domain)"

# get domain register info
get_domain_register_info(){
    domain_prompt
    curl -X GET https://api.godaddy.com/v1/domains/$domain \
        -H "accept: $accept" \
        -H "Content-Type: $Content" \
        -H "Authorization: $Authorization"
}

# get dns record
get_dns_record(){
    domain_prompt
    record_type_prompt
    record_prompt
    curl -X GET https://api.godaddy.com/v1/domains/$domain/records/$record_type/$record \
        -H "accept: $accept" \
        -H "Content-Type: $Content" \
        -H "Authorization: $Authorization"
}

# update dns record
update_dns_record(){
        domain_prompt
        record_type_prompt
        record_prompt
        domain_ip_prompt
        curl -X PUT https://api.godaddy.com/v1/domains/$domain/records/$record_type/$record \
            -H "accept: $accept" \
            -H "Content-Type: $Content" \
            -H "Authorization: $Authorization" \
            -d "[ { \"data\": \"$domain_ip\", \"port\": 65535, \"priority\": 1, \"protocol\": \"string\", \"service\": \"string\", \"ttl\": 600, \"weight\": 1 } ]"
}

# add dns recored
add_dns_record(){
    domain_ip_prompt
    record_prompt
    record_type_prompt
    curl -X PATCH https://api.godaddy.com/v1/domains/$domain/records \
        -H "accept: $accept" \
        -H "Content-Type: $Content" \
        -H "Authorization: $Authorization" \
        -d "[ { \"data\": \"$domain_ip\", \"name\": \"$record\", \"port\": 65535, \"priority\": 0, \"protocol\": \"string\", \"service\": \"string\", \"ttl\": 600, \"type\": \"$record_type\",\"weight\": 1 } ]"
}

# delete dns record
del_dns_record(){
    domain_prompt
    record_type_prompt
    record_prompt
    curl -X DELETE 'https://api.godaddy.com/v1/domains/$domain/records/$record_type/$record' \
        -H "accept: $accept" \
        -H "Content-Type: $Content" \
        -H "Authorization: $Authorization"
}

# get account domian list
get_account_domain_list(){
    curl -X GET "https://api.godaddy.com/v1/domains?statuses=ACTIVE" -H "accept: $accept" -H "Authorization: $Authorization"|jq '.[]' domain_list.txt|jq '.domain,.createdAt,.expires' |paste - - -
}

menu_prompt(){
  read -p "please input num: " option
}

menu(){
  cat<<-EOF
  1)  get_domain_register_info
  2)  get_dns_record
  3)  update_dns_record
  4)  add_dns_record
  5)  del_dns_record
  6)  get_account_domain_list
EOF
}

menu
while true
do
  menu_prompt
  clear
  menu
  case $option in
    1)
      get_domain_register_info
      ;;
    2)
      get_dns_record
      ;;
    3)
      update_dns_record
      ;;
    4)
      add_dns_record
      ;;
    5)
      del_dns_record
      ;;
    6)
      get_account_domain_list
      ;;
    "")
      menu_prompt
      ;;
    q)
      break
      ;;
    *)
      menu_prompt
      ;;
  esac
done
