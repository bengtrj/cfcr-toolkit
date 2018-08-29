#!/bin/bash
set -x

export director_name="$(bbl outputs | bosh int - --path=/director_name)"
export address="https://${kubernetes_master_host}:8443"
export cluster_name="kubo:${director_name}:cfcr"
export user_name="kubo:${director_name}:cfcr-admin"

credhub login
export admin_password=$(credhub get -n "${director_name}/cfcr/kubo-admin-password" --output-json | bosh int - --path=/value)

# add this credhub-generated CA to your system keyring if you'd like to authenticate without --insecure-skip-tls-verify=true
export tmp_ca_file="$(mktemp)"
credhub get -n "${director_name}/cfcr/tls-kubernetes" --output-json | bosh int - --path=/value/ca > "${tmp_ca_file}"

cat <<EOF > config
apiVersion: v1
kind: Config
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: ${address}
  name: "${cluster_name}"
contexts:
- context:
    cluster: "${cluster_name}"
    user: "${user_name}"
  name: "${cluster_name}"
current-context: "${cluster_name}"
users:
- name: "${user_name}"
  user:
    token: "${admin_password}"

EOF

#kubectl config set-cluster "${cluster_name}" --server="${address}" --insecure-skip-tls-verify=true
#kubectl config set-credentials "${user_name}" --token="${admin_password}"
#kubectl config set-context "${cluster_name}" --cluster="${cluster_name}" --user="${user_name}"
#kubectl config use-context "${cluster_name}"
