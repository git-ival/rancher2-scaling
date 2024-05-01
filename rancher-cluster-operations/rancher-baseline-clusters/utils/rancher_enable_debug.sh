#!/usr/bin/env bash

kubectl -n cattle-system get pods -l app=rancher --no-headers -o custom-columns=name:.metadata.name | while read rancherpod; do kubectl -n cattle-system exec "$rancherpod" -c rancher -- loglevel --set "debug"; done
