#!/usr/bin/env bash

# Typical invocation

# govc_clear_networking.sh > ~/tmp/dvportgroup.info

# Used when you get the following error (you lost your vCenter and are
# recreating it):

# The host proxy switch associated with esxi-1.nono.io no longer exists in
# vCenter Server. vCenter Server is not able to automatically remove the host
# proxy switch because it is still in use. To resolve the issue, disconnect any
# VMs and VMkernel network adapters that might be connected to the switch and
# remove the switch.

# The following loop prints out the existing port group info so youu can
# reconnect your VMs' network connection after receating the DVswitch & port
# groups (e.g. "dvportgroup-1036" → "guest")
for VM in $(govc ls /dc/host/cl/esxi-1.nono.io); do
  echo $VM:
  govc device.info -json -vm $VM 'ethernet-*' |
    jq -r '.Devices[] | select(.backing.DeviceName != "VM Network") | select(.Backing.Port.PortgroupKey != null) | {Name,"Summary": .Backing["Port"]["PortgroupKey"]}'
done

# The following loop sets the networks connected to a DVS portgroup
# to "VM Network"
for VM in $(govc ls /dc/host/cl/esxi-1.nono.io); do
  echo $VM:
  for NIC in $(govc device.info -json -vm $VM 'ethernet-*' |
    jq -r '.Devices[] | select(.backing.DeviceName != "VM Network") | select(.Backing.Port.PortgroupKey != null) | .Name'); do
    govc vm.network.change -vm $VM -net "VM Network" $NIC
  done
done
