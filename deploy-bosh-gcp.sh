#!/usr/bin/env bash

set -e

# Maybe install necessary CLIs? Depends on the system!
# bosh-cli, bbl, gcloud

[[ -z "${DEBUG:-}" ]] || set -x

iaas=gcp
bbl_state_directory=bbl-state
bosh_deployment_name=cfcr-bosh
gcp_region=""
gcp_project_name=""
gcp_account_file_path=""
dns_name=""

print_usage() {
cat >&2 << EOF

Usage: $0 <GCP project name> <GCP region> <DNS name> [GCP account file path]

Mandatory parameters:
<GCP project name>          the GCP project to target the BOSH deployment

<GCP region>                the GCP region to use when creating resources

<DNS Name>                  a DNS name (eg. yourcompany.com) - this will be used as a basis
                            to all subsequent CFCR clusters created so you can connect with
                            the Master node using kubectl.
                            Subsequently created clusters will have their addresses specified as the
                            cluster name appended to this DNS name (eg. my-cluster-name.yourcompany.com)

Optional parameters:
[GCP account file path]     you can provide your service account JSON key path
                            Optionally, you can skip this parameter if you're logged in to gcloud cli - then
                            this script will create a service account / key for you using gcloud cli
EOF
}

# Sets up the gcp_account variable, creating a service account if none were provided.
setupServiceAccount() {
    if [[ -z "${gcp_account_file_path}" ]]
    then
        gcp_account_file_path="${bosh_deployment_name}"-key.json # how to secure this?
        gcp_account="${bosh_deployment_name}@${gcp_project_name}.iam.gserviceaccount.com"

        print "Creating service account ${gcp_account}..."

        gcloud iam service-accounts create "${bosh_deployment_name}" --display-name="${bosh_deployment_name}"
        gcloud projects add-iam-policy-binding "${gcp_project_name}" --member serviceAccount:"${gcp_account}" --role roles/owner >> /dev/null
        gcloud iam service-accounts keys create "${gcp_account_file_path}" --iam-account="${bosh_deployment_name}@${gcp_project_name}.iam.gserviceaccount.com"
    else
        gcp_account="$(bosh int "${gcp_account_file_path}" --path=/client_email)"

        print "Using existing service account ${gcp_account}"
    fi
}

setupNetworking() {
    echo "dns-zone: ${bosh_deployment_name}-cfcr-dns-zone" >> "${bbl_state_directory}/bosh_config.yml"
    gcloud dns managed-zones create "${bosh_deployment_name}-cfcr-dns-zone" --description="DNS zone for the ${bosh_deployment_name} cfcr environment" --dns-name="${dns_name}"

}

setupDependencies() {
    mkdir -p "${bbl_state_directory}"
    pushd "${bbl_state_directory}"
        print "Cloning necessary repos"
        git clone https://github.com/cloudfoundry-incubator/kubo-deployment.git
    popd
}

deployBoshDirector() {

    export BBL_GCP_REGION="${gcp_region}"
    export BBL_GCP_SERVICE_ACCOUNT_KEY="${gcp_account_file_path}"
    export BBL_ENV_NAME="${bosh_deployment_name}"
    export BBL_IAAS="${iaas}"
    export BBL_STATE_DIRECTORY="${bbl_state_directory}"

    echo "BBL Dir: ${BBL_STATE_DIRECTORY}"

    print "Setting up BOSH director"
    bbl plan

    print "Deploying BOSH director"
    bbl up --debug 2>&1 > bbl_up.log

    # This will setup the BOSH env variables so we can issue bosh commands
    eval "$(bbl print-env | grep -vE "BOSH_ALL_PROXY|CREDHUB_PROXY")"

    print "Creating a .envrc file"
    cat << EOF > .envrc
echo Setting up BOSH director env variables
export BBL_STATE_DIRECTORY=${BBL_STATE_DIRECTORY}
eval "\$(bbl print-env | grep -vE "BOSH_ALL_PROXY|CREDHUB_PROXY")"

echo Setting up kubectl communication

EOF

    print "All done! Now you can run `direnv allow` if you have direnv installed, or just `source .envrc`"
}

print() {
    echo -e "\n****** $1 ******\n"
}

main() {
    gcp_project_name=$1
    gcp_region=$2
    dns_name=$3
    gcp_account_file_path=$4
    if [[ -z "${gcp_project_name}" || -z "${gcp_region}" || -z "${dns_name}" ]]; then
        print_usage
        exit 1
    fi
    setupDependencies
    setupServiceAccount
    deployBoshDirector
}

[[ "$0" == "${BASH_SOURCE[0]}" ]] && main "$@"