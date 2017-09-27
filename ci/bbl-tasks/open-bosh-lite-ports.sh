#!/bin/bash

set -eu -o pipefail

# ENV
: "${BBL_STATE_DIR:?}"
: "${GCP_SERVICE_ACCOUNT_KEY:?}"
: "${GCP_PROJECT_ID:?}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
bbl_state_dir="${workspace_dir}/bbl-state/${BBL_STATE_DIR}"

tmp_dir="$(mktemp -d /tmp/open-bosh-lite-ports.XXXXXXXX)"
trap '{ rm -rf "${tmp_dir}"; }' EXIT

open_bosh_lite_ports() {
  service_key_path="${tmp_dir}/gcp.json"
  echo "${GCP_DNS_SERVICE_ACCOUNT_KEY}" > "${service_key_path}"
  gcloud auth activate-service-account --key-file="${service_key_path}"
  gcloud config set project "${GCP_PROJECT_ID}"

  firewall_rule_name="${GCP_PROJECT_ID}-bosh-lite"

  if ! gcloud compute firewall-rules describe "${firewall_rule_name}"; then
    bbl_state_path="${bbl_state_dir}/bbl-state.json"
    director_tag="$(jq -r .tfState "${bbl_state_path}" | jq -r .modules[0].outputs.bosh_director_tag_name.value)"
    director_network="$(jq -r .tfState "${bbl_state_path}" | jq -r .modules[0].outputs.network_name.value)"

    gcloud compute firewall-rules \
      create "${firewall_rule_name}" \
      --allow=tcp:80,tcp:443,tcp:2222 \
      --source-ranges 0.0.0.0/0 \
      --target-tags "${director_tag}" \
      --network "${director_network}"
  fi
}

pushd "${bbl_state_dir}" > /dev/null
  open_bosh_lite_ports
popd > /dev/null
