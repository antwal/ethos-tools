#!/bin/bash

layout=""
variant=""

tmp=~/.ethos-tools/tmp
config=~/.config/lxsession/LXDE/autostart
keyboard="setxkbmap -layout \"@layout\" -variant \"@variant\""

function multi { 
	echo $1
	nl -w8 -s. $2 | column
	count="$(wc -l $2 | cut -f 1 -d' ')"
	n=""
	while true; do
	  read -p 'Select option: ' n
	  if [ "$n" -eq "$n" ] && [ "$n" -gt 0 ] && [ "$n" -le "$count" ]; then
	    break
	  fi
	done

	value="$(sed -n "${n}p" $2 | cut -f 3 -d' ')"
	echo "$3 number $n: '$value'"
	result="$value"
}

clear

mkdir -p $tmp

# Keyboard Layouts
sed '/^! layout$/,/^ *$/!d;//d' < /usr/share/X11/xkb/rules/base.lst > $tmp/layouts.lst

multi "Please select your keyboard layout:" "$tmp/layouts.lst" "Selected keyboard layout"
layout="$result"

# Keyboard Layout Variants
sed '/! variant/,/^$/!d;/'$layout':/!d' < /usr/share/X11/xkb/rules/evdev.lst > $tmp/variants.lst
sed -e 's/'$layout'://g' < $tmp/variants.lst > $tmp/variants.$layout.lst

multi "Please select your keyboard layout variant:" "$tmp/variants.$layout.lst" "Selected keyboard layout variant"
variant="$result"

# New Keyboard Layout
kbtmp="${keyboard//@layout/$layout}"
kbmap="${kbtmp//@variant/$variant}"

if grep -q "setxkbmap" $config; then
  # Overwrite
  echo "Keyboard layout is configured"
  while true; do
    read -p "Do you want to overwrite settings (y/n): " yn
    case $yn in
       [Yy]* ) sed -i.bak "s/.*setxkbmap.*/${kbmap}/g" $config; break;;
       [Nn]* ) exit;;
       * ) echo "Please answer yes or no.";;
    esac
  done
else
  # Append
  echo "$kbmap" >> $config
fi
