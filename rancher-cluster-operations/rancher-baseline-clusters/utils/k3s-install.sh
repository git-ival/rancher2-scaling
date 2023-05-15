#!/bin/bash
export INSTALL_K3S_VERSION='${install_k3s_version}'
export K3S_CLUSTER_SECRET='${k3s_cluster_secret}'
export K3S_TOKEN='${k3s_cluster_secret}'

%{ if sleep_at_startup }
sleep_time=$(((RANDOM % 10) + 25))
sleep $sleep_time
%{ endif ~}

until (${install_command}); do
  echo 'k3s did not install correctly'
  systemctl status k3s.service
  journalctl -xe --no-pager -u k3s.service
  k3s-uninstall.sh
  sleep 2
done

until kubectl get pods -A | grep 'Running'; do
  echo 'Waiting for k3s startup'
  sleep 5
done
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >>~/.bashrc
echo 'source <(kubectl completion bash)' >>~/.bashrc
