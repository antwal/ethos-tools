#!/bin/bash

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

require_package "jq"

echo "Checking your timezone from public ip address...."
TZ=$(curl -sS http://ip-api.com/json | jq -r '.timezone')

if [ "$TZ" = "null" ]; then
  echo "Unable to determine timezone from public ip address."
  # Manually select
else
  echo "Your timezone is '$TZ'"
  MATCH=$(timedatectl list-timezones | egrep "^${TZ}$")
  if [ "MATCH" = "" ]; then
    echo "Timezone '$TZ' doesn't match any locally available zone."
    # Manually Select
  else
    echo "The locally zone is '$MATCH'"
    sudo timedatectl set-timezone "$TZ" && echo "Updated timezone to '$TZ'" || echo "Unable to set timezone to '$TZ'"
  fi
fi

