#!/usr/bin/env bash

### $1 - path to data file or directory of files to load into all configmaps

for i in {1..80000}
do
  map_name="test-configmap-${i}"
  kubectl create configmap "${map_name}" --from-file="${1}"
done
