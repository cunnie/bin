#!/usr/bin/env bash
# export GOVC_URL='https://administrator@vsphere.local:password@vcenter-80.nono.io'
# export PIVNET_API_TOKEN='svJuxxxxxxxxxxxxxxxx'

set -ex

pivnet login --api-token=$PIVNET_API_TOKEN
pivnet download-product-files --product-slug='ops-manager' --release-version='2.10.53' --product-file-id=1424065
pivnet download-product-files --product-slug='elastic-runtime' --release-version='2.13.15' --product-file-id=1422201

# govc import.spec ~/Downloads/ops-manager-vsphere-2.10.53-build.707.ova > /tmp/junk.json
SPEC_JSON='
{
  "DiskProvisioning": "flat",
  "IPAllocationPolicy": "dhcpPolicy",
  "IPProtocol": "IPv4",
  "PropertyMapping": [
    {
      "Key": "ip0",
      "Value": "10.9.251.10"
    },
    {
      "Key": "netmask0",
      "Value": "255.255.255.0"
    },
    {
      "Key": "gateway",
      "Value": "10.9.251.1"
    },
    {
      "Key": "DNS",
      "Value": "10.9.251.1,8.8.8.8"
    },
    {
      "Key": "ntp_servers",
      "Value": "time.google.com"
    },
    {
      "Key": "public_ssh_key",
      "Value": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWiAzxc4uovfaphO0QVC2w00YmzrogUpjAzvuqaQ9tD cunnie@nono.io"
    },
    {
      "Key": "custom_hostname",
      "Value": "om.tas.nono.io"
    }
  ],
  "NetworkMapping": [
    {
      "Name": "Network 1",
      "Network": "TAS"
    }
  ],
  "Annotation": "Tanzu Ops Manager installs and manages products and services.",
  "MarkAsTemplate": false,
  "PowerOn": true,
  "InjectOvfEnv": false,
  "WaitForIP": false,
  "Name": "om.tas.nono.io"
}
'
govc import.ova -dc=dc -ds=NAS-0 -pool=TAS -options=<(echo $SPEC_JSON) -k ~/Downloads/ops-manager-vsphere-2.10.53-build.707.ova

export OM_USERNAME=admin OM_PASSWORD=admin OM_TARGET=om.tas.nono.io OM_SKIP_SSL_VALIDATION=true
om upload-product srt-2.13.15-build.2.pivotal
