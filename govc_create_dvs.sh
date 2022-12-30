#!/usr/bin/env zsh

# Useful when your vCenter has cratered and you
# need to recreate everything.

govc dvs.create -mtu 1600 DSwitch
govc dvs.portgroup.add -dvs DSwitch           nono
govc dvs.portgroup.add -dvs DSwitch           "Management Network"
govc dvs.portgroup.add -dvs DSwitch -vlan 2   guest
govc dvs.portgroup.add -dvs DSwitch -vlan 240 k8s
govc dvs.portgroup.add -dvs DSwitch -vlan 250 CF
govc dvs.portgroup.add -dvs DSwitch -vlan 251 TAS
govc dvs.portgroup.add -dvs DSwitch -vlan-mode=trunking all-VLANs
echo "Remember to allow Promiscuous Mode and Forged Transmits on all-VLANs"
