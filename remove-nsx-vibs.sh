#!/bin/sh
#
# Remove NSX-T 2.4 VIBs (kernel modules) from ESXi host
#
esxcli software vib remove \
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
