#!/usr/bin/env ruby
#
# Placate rubocop:
# frozen_string_literal: true

require 'rbvmomi'
require 'pry-byebug'

raise 'set GOVC_{URL,USERNAME,PASSWORD}' unless
  ENV.include?('GOVC_URL') &&
  ENV.include?('GOVC_USERNAME') &&
  ENV.include?('GOVC_PASSWORD')

vim = RbVmomi::VIM.connect(
  host: ENV['GOVC_URL'],
  user: ENV['GOVC_USERNAME'],
  password: ENV['GOVC_PASSWORD']
) || raise("couldn't log in")
dc = vim.serviceInstance.find_datacenter('dc') || raise('datacenter not found')
cl = dc.find_compute_resource('cl')
esxi1 = cl.host.select { |host| host.name == 'esxi-1.nono.io' }.first
esxi2 = cl.host.select { |host| host.name == 'esxi-2.nono.io' }.first
esxi1.config.graphicsConfig
esxi1.configManager.graphicsManager.sharedPassthruGpuTypes # ["grid_t4-4q", etc.]
# esxi1.config.pciPassthruInfo
lunar = esxi2.vm.select { |vm| vm.name == 'lunar.nono.io' }.first
devices = lunar.config.hardware.device
pci_pass = devices.select { |dev| dev.instance_of?(RbVmomi::VIM::VirtualPCIPassthrough) }.first
devices.delete(devices.index(pci_pass)) # <-- doesn't remove the device
binding.pry
devices.class
