#!/usr/bin/env ruby
#
# Run the following if your BOSH certs have expired. Then redeploy
# (`create-env`) your BOSH Director.
#
# It clears out the certificates, which forces BOSH to regenerate
# them
#
# RECREATE ALL YOUR DEPLOYMENTS AFTERWARDS! `deploy --recreate`
#
# How to use:
#   clear_bosh_certs.rb < bosh-creds.yaml > bosh-creds.yaml-new
#   mv bosh-creds.yaml-new bosh-creds.yaml
#
require 'yaml'

state_json = YAML.load($stdin)
%w(
  blobstore_ca
  blobstore_server_tls
  credhub_ca
  credhub_tls
  default_ca
  director_ssl
  mbus_bootstrap_ssl
  nats_ca
  nats_clients_director_tls
  nats_clients_health_monitor_tls
  nats_server_tls
  uaa_service_provider_ssl
  uaa_ssl
).each do |key|
  state_json.delete(key)
end
print YAML.dump(state_json)
