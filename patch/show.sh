#!/bin/bash

version="$(cat /opt/ethos/etc/version)"

url="https://raw.githubusercontent.com/antwal/ethos-tools/master/patch/$version/show.patch"

echo "Checking patch file, please wait..."

if curl -f ${url} >/dev/null 2>&1; then
  curl -s $url | sudo patch -d/ -p0
else
  echo "Patch file not available for version ($version)."
  exit 0
f

