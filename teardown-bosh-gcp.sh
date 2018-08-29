#!/usr/bin/env bash

set -e

# Maybe install necessary CLIs? Depends on the system!
# bosh-cli, bbl, gcloud

[[ -z "${DEBUG:-}" ]] || set -x

bosh_deployment_name=cfcr-bosh-gcp

#print_usage() {
#cat >&2 << EOF
#
#EOF
#}

main() {
    gcloud dns managed-zones delete "${bosh_deployment_name}"

    gcloud iam service-accounts keys delete cc8b3ef4287bf62abc4cdace058ebb79919aba8f --iam-account="${bosh_deployment_name}@${gcp_project_name}.iam.gserviceaccount.com"
    gcloud iam service-accounts delete "${bosh_deployment_name}@${gcp_project_name}.iam.gserviceaccount.com"
}

[[ "$0" == "${BASH_SOURCE[0]}" ]] && main "$@"