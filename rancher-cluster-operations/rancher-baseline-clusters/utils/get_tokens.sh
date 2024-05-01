#!/usr/bin/env bash

### Get all Local cluster `Tokens`
kubectl get tokens -A -o jsonpath='{range .items[*]}{.token}{"\n"}{end}'

### Get all Downstream cluster `clusterauthtokens`
kubectl get clusterauthtokens -A -o jsonpath='{range .items[*]}{@.hash}{"\n"}{end}'
