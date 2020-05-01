#!/bin/sh
#
# Remove NSX-T 2.4 VIBs (kernel modules) from ESXi host
#
# THIS NEVER WORKED! I reinstalled ESXi from scratch
#
# Thanks https://brianragazzi.wordpress.com/2017/10/31/removing-nsx-t-vibs-from-esxi-hosts/

# Run the following TWICE to fix
#   KernelModulesException: Failed to unload module nsxt-vsip: vmkmod: VMKMod_UnloadModule: Unloading module nsxt-vsip failed: Busy (bad0004)
/etc/init.d/netcpad stop
/etc/init.d/nsx-ctxteng stop remove
/etc/init.d/nsx-da stop remove
/etc/init.d/nsx-datapath stop remove
/etc/init.d/nsx-exporter stop remove
/etc/init.d/nsx-hyperbus stop remove
/etc/init.d/nsx-lldp stop remove
/etc/init.d/nsx-mpa stop remove
/etc/init.d/nsx-nestdb stop remove
/etc/init.d/nsx-opsagent stop remove
/etc/init.d/nsx-platform-client stop remove
/etc/init.d/nsx-pre-nestdb stop remove
/etc/init.d/nsx-pre-netcpa stop remove
/etc/init.d/nsx-proxy stop remove
/etc/init.d/nsx-sfhc stop remove
/etc/init.d/nsx-support-bundle-client stop remove
/etc/init.d/nsxa stop remove
/etc/init.d/nsxcli stop remove
/etc/init.d/nsx-context-mux stop remove

# thanks https://docs.vmware.com/en/VMware-NSX-T-Data-Center/2.4/installation/GUID-A4CA075F-7E0B-4375-9DCD-27814B8E818F.html
# esxcli software vib list | grep -E 'nsx|vsipfwlib' | awk '{print $1}' | sed 's=^=  -n =;s=$= \\='
esxcli software vib remove --force \
  -n nsx-adf \
  -n nsx-aggservice \
  -n nsx-cli-libs \
  -n nsx-common-libs \
  -n nsx-esx-datapath \
  -n nsx-exporter \
  -n nsx-host \
  -n nsx-metrics-libs \
  -n nsx-mpa \
  -n nsx-nestdb-libs \
  -n nsx-nestdb \
  -n nsx-netcpa \
  -n nsx-opsagent \
  -n nsx-platform-client \
  -n nsx-profiling-libs \
  -n nsx-proxy \
  -n nsx-python-greenlet \
  -n nsx-python-protobuf \
  -n nsx-rpc-libs \
  -n nsx-shared-libs \
  -n nsx-upm-libs \
  -n nsxcli \
  -n vsipfwlib \


  -n nsx-context-mux \

  -n nsx-nestdb-libs \
  -n nsx-common-libs \
  -n nsx-netcpa \
  -n nsx-upm-libs \
  -n nsx-aggservice \
  -n nsx-python-protobuf \
  -n vsipfwlib \
  -n nsx-metrics-libs \
  -n nsx-vdpi \
  -n nsx-sfhc \
  -n nsx-python-logging \
  -n nsx-cli-libs \
  -n nsx-python-gevent \
  -n nsx-mpa \
  -n nsx-adf \
  -n nsx-shared-libs \
  -n nsx-platform-client \
  -n nsx-exporter \
  -n nsx-nestdb \
  -n nsx-rpc-libs \
  -n nsx-esx-datapath \
  -n nsx-python-greenlet \
  -n nsx-opsagent \
  -n nsx-context-mux \
  -n nsx-host \
  -n nsx-profiling-libs \
  -n nsxcli \
  -n nsx-proxy \

