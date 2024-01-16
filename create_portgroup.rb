#!/usr/bin/env ruby
require 'rbvmomi'
require 'pry-byebug'

# Set your vCenter server details and credentials
# Connect to vCenter
vim = RbVmomi::VIM.connect(
  host: 'vcenter-80.nono.io',
  user: 'a@vsphere.local',
  password: 'xxx',
)

# Specify the distributed virtual switch (DVS) and VLAN ID
dvs_name = 'DSwitch'
vlan_id = 1024

# Create distributed virtual switch
dvs = vim.serviceInstance.find_datacenter.networkFolder.childEntity.select { |n| n.name == dvs_name }.first

# Create distributed virtual port group
dv_pg_config = RbVmomi::VIM.DVPortgroupConfigSpec(
  name: 'delete-me',
  type: 'ephemeral',
  numPorts: 16,
  defaultPortConfig: RbVmomi::VIM.VMwareDVSPortSetting(
    vlan: RbVmomi::VIM.VmwareDistributedVirtualSwitchVlanIdSpec(inherited: false, vlanId: vlan_id)
  )
)

# binding.pry
dvs.AddDVPortgroup_Task(spec: [dv_pg_config]).wait_for_completion

# Disconnect from vCenter
vim.close
