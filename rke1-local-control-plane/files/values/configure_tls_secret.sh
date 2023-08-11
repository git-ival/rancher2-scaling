#!/usr/bin/env bash

%{ if !install_certmanager && install_byo_certs ~}
mkdir ${cluster_file_dir}/
cd certs/
apt-get update \
 && apt-get install atool --yes \
 && apt-get install awscli --yes \
 && aws --region "${s3_bucket_region}" s3 cp s3://"${byo_certs_bucket_path}" ${cluster_file_dir}/temp_cert

# tar -xf certs.tar.gz --strip-components 1
atool -X ./ temp_cert # NOTE: the given archive must contain a certs/ directory in which all cert files are stored for this to work
mv "${cluster_file_dir}/${tls_cert_file}" ${cluster_file_dir}/tls.crt
mv "${cluster_file_dir}/${tls_key_file}" ${cluster_file_dir}/tls.key

if [[ ! $(kubectl get secrets -n cattle-system | grep -q tls-rancher-ingress) ]]; then
  kubectl -n cattle-system create secret tls tls-rancher-ingress \
    --cert="${cluster_file_dir}/tls.crt" \
    --key="${cluster_file_dir}/tls.key"
fi

%{ if private_ca ~}
mv "${cluster_file_dir}/${private_ca_file}" ${cluster_file_dir}/cacerts.pem
if [[ ! $(kubectl get secrets -n cattle-system | grep -q tls-ca) ]]; then
  kubectl -n cattle-system create secret generic tls-ca \
    --from-file=cacerts.pem="${cluster_file_dir}/cacerts.pem"
fi
%{ endif ~}

# find . -type f ! -name "*.key" ! -name "*.crt" ! -name "cacerts.pem" -exec rm {} \;
rm -rf ${cluster_file_dir}/

%{ endif ~}
