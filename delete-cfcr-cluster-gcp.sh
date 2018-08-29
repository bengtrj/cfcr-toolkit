#!/usr/bin/env bash

set -e

[[ -z "${DEBUG:-}" ]] || set -x

cfcr_cluster_name=""
cfcr_cluster_region=""
bbl_state_directory=bbl-state

print_usage() {
cat >&2 << EOF

Usage: $0 <CFCR cluster name>

Mandatory parameters:
<CFCR cluster name>          the CFCR cluster name (BOSH deployment name).
EOF
}

cleanup_networking() {
    gcloud compute addresses delete "${cfcr_cluster_name}-gcp-cfcr" "${cfcr_cluster_name}-gcp-jumpbox-ip"  --region="${cfcr_cluster_region}" --quiet
    echo "Delete me"
}

delete_cfcr_deployment() {

cfcr_cluster_region="$(bosh int bbl-state/bbl-state.json --path=/gcp/zone)"
bosh delete-deployment -d "${cfcr_cluster_name}"

}

print() {
    echo -e "\n****** $1 ******\n"
}

main() {
    delete_cfcr_deployment
    cleanup_networking
}

[[ "$0" == "${BASH_SOURCE[0]}" ]] && main "$@"