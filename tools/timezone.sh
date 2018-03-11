#!/bin/bash

timezone=/tmp/timezone.lst
timezone_num=/tmp/timezone_num.lst
lines=$(tput lines)
re='^[0-9]+$'

function require_package {
  for package in $1; do
    echo "Checking for required packages..."
    if (dpkg --get-selections | grep -q "^$package[[:space:]]*install$" >/dev/null); then
      echo "${package} is installed." > /dev/null
    else
      echo "Installing package ${package}..."
      sudo DEBIAN_FRONTEND=noninteractive apt-get-ubuntu -yq install $package
    fi
  done
}

function set_timezone {
  sudo timedatectl set-timezone "$1" && echo "Updated timezone to '$1'" || echo "Unable to set timezone to '$1'"
}

function show_timezones {
  start=$1
  end=$2
  sed -n "${start},${end}p" $3 | column
}

function manual_timezone {
  # Manually select
  timedatectl list-timezones > $timezone
  nl -w8 -s." " $timezone > $timezone_num
  count="$(wc -l $timezone | cut -f 1 -d' ')"
  choice=""
  n=1
  l=$lines
  p=1
  pt=$(echo "scale=2;($count/$lines)" | bc)
  pt=$(echo "scale=0;($pt+0.5)/1" | bc)
  while true; do
    clear
    echo "Select your time zone number:"
    echo
    show_timezones "$n" "$l" $timezone_num
    echo
    read -p "[(n)ext page ($p/$pt)]: " choice
    if ! [[ $choice =~ $re ]] && [ "$choice" == "n" ] && [ ! "$p" -eq "$pt" ]; then
      n=$(($n + $lines))
      l=$(($l + $lines))
      p=$(($p + 1))
    elif [[ $choice =~ $re ]] && [ "$choice" -eq "$choice" ] && [ "$choice" -gt 0 ] && [ "$choice" -le "$count" ]; then
      value=$(sed -n "${choice}p" $timezone | cut -f 3 -d' ')
      set_timezone "$value"
      break
    fi
  done
}

function ask_manual {
  while true; do
    read -p "Do you want configure it manually (y/n): " yn
    case $yn in
       [Yy]* ) manual_timezone; break;;
       [Nn]* ) exit;;
       * ) echo "Please write (y)es or (n)o";;
    esac
  done
}

clear

require_package "jq"

echo "Checking your timezone from public ip address...."
TZ=$(curl -sS http://ip-api.com/json | jq -r '.timezone')

if [ "$TZ" = "null" ]; then
  echo "Unable to determine timezone from public ip address."
  # Manually select
  ask_manual
else
  echo "Your timezone is '$TZ'"
  MATCH=$(timedatectl list-timezones | egrep "^${TZ}$")
  if [ "MATCH" = "" ]; then
    echo "Timezone '$TZ' doesn't match any locally available zone."
    # Manually Select
    ask_manual
  else
    echo "The locally zone is '$MATCH'"
    # sudo timedatectl set-timezone "$TZ" && echo "Updated timezone to '$TZ'" || echo "Unable to set timezone to '$TZ'"
    set_timezone "$TZ"
  fi
fi

