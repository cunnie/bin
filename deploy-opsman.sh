#!/usr/bin/env zsh

# govc import.spec ~/Downloads/ops-manager-vsphere-2.10.19-build.314.ova | pbcopy
set -euo pipefail

if [ "${GOVC_PASSWORD:-not_set}" = "not_set" ]; then
  echo "must set GOVC_PASSWORD"
  exit 1
fi

export GOVC_USERNAME=administrator@vsphere.local \
  GOVC_URL=vcenter-70.nono.io

tee /tmp/opsman-$$.json <<EOF
{
  "DiskProvisioning": "flat",
  "IPAllocationPolicy": "fixedPolicy",
  "IPProtocol": "IPv4",
  "PropertyMapping": [
    {
      "Key": "ip0",
      "Value": "10.0.251.10"
    },
    {
      "Key": "netmask0",
      "Value": "255.255.255.0"
    },
    {
      "Key": "gateway",
      "Value": "10.0.251.1"
    },
    {
      "Key": "DNS",
      "Value": "8.8.8.8"
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
      "Network": "tas"
    }
  ],
  "Annotation": "Tanzu Ops Manager installs and manages products and services.",
  "MarkAsTemplate": false,
  "PowerOn": false,
  "InjectOvfEnv": false,
  "WaitForIP": false,
  "Name": null
}

EOF

 govc import.ova -options=/tmp/opsman-$$.json \
   -ds=NAS-0 \
   -name=om.tas.nono.io \
   -pool=TAS \
   ~/Downloads/ops-manager-vsphere-2.10.19-build.314.ova
