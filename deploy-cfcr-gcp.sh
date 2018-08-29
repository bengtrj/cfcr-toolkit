#!/usr/bin/env bash

set -e

[[ -z "${DEBUG:-}" ]] || set -x

bosh_deployment_name=cfcr-bosh-gcp
kubernetes_master_host=""
bosh_dns_zone="$(bosh int ${bbl_state_directory}/bosh_config.yml --path=/dns-zone)"

print_usage() {
cat >&2 << EOF

Usage: $0 <CFCR cluster name>

Mandatory parameters:
<CFCR cluster name>          the CFCR cluster name. This will be the BOSH deployment name for the cluster too.

EOF
}

setup_networking() {
    gcloud dns record-sets transaction start \
            --zone="${bosh_dns_zone}"

    gcloud dns record-sets transaction add \
            --ttl=300 \
            --name="${cfcr_cluster_name}" \
            --type=A \
            --zone="${bosh_dns_zone}"

    gcloud dns record-sets transaction execute \
            --zone="${bosh_dns_zone}"
}

setup_node_service_acccounts() {
    # master node
    gcloud iam service-accounts create "${bosh_deployment_name}" --display-name="${bosh_deployment_name}"
    gcloud projects add-iam-policy-binding "${gcp_project_name}" --member serviceAccount:"${gcp_account}" --role roles/owner >> /dev/null

    # worker node
}

deploy_cfcr() {

export KD="$(pwd)/${bosh_deployment_name}/kubo-deployment"

bosh deploy -d "${cfcr_cluster_name}" "${KD}/manifests/cfcr.yml" \
-o "${KD}/manifests/ops-files/iaas/gcp/cloud-provider.yml" \
-o "${bosh_deployment_name}/cfcr-ops.yml" \
-v deployment_name="${cfcr_cluster_name}" \
-v kubernetes_master_host="${kubernetes_master_host}" \
-l <(bbl outputs) --non-interactive

}

# Upload default stemcell for GCP to director blobstore - https://bosh.cloudfoundry.org/stemcells/ - https://ultimateguidetobosh.com/stemcells/
upload_stemcell() {
    local stemcell_version
    stemcell_version="$(bosh int "${bbl_state_directory}"/kubo-deployment/manifests/cfcr.yml --path /stemcells/0/version)"

    print "Uploading the bosh GCP stemcell version ${stemcell_version}"
    bosh upload-stemcell "https://s3.amazonaws.com/bosh-gce-light-stemcells/light-bosh-stemcell-${stemcell_version}-google-kvm-ubuntu-trusty-go_agent.tgz"
}

upload_cfcr_release() {
    print "Uploading CFCR release"
    bosh upload-release $(curl --silent "https://api.github.com/repos/cloudfoundry-incubator/kubo-release/releases/latest" | bosh int - --path=/assets/0/browser_download_url | grep http)
}

print() {
    echo -e "\n****** $1 ******\n"
}

main() {
    eval "$(BBL_STATE_DIRECTORY="bbl-state" bbl print-env | grep -vE "BOSH_ALL_PROXY|CREDHUB_PROXY")"

    cfcr_cluster_name=$1
    kubernetes_master_host=$2

    if [[ -z "${cfcr_cluster_name}" || -z "${kubernetes_master_host}" ]]; then
        print_usage
        exit 1
    fi

#    upload_cfcr_release
    deploy_cfcr
}

[[ "$0" == "${BASH_SOURCE[0]}" ]] && main "$@"