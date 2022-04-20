#!/bin/bash

declare -A l_os
l_os=(
  [barbican]=barbican-manage 
  [cinder]=cinder-manage 
  [glance]=glance-api 
  [keystone]=keystone-manage 
  [neutron]=neutron-server 
  [nova]=nova-manage)

for k in "${!l_os[@]}"; do
  v=$(sudo ${l_os[$k]} --version 2>/dev/null)
  echo "$k: $v"
done
