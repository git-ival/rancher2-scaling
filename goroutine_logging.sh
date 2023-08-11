#!/usr/bin/env bash

function goroutine_error_logs() {
  while true; do
    for pod in $(kubectl get pods -n cattle-system --no-headers -l app=rancher | cut -d ' ' -f1); do
      kubectl exec -n cattle-system $pod -- curl -s http://localhost:6060/debug/pprof/goroutine -o goroutine
      kubectl cp cattle-system/${pod}:goroutine ./goroutine
      go tool pprof -top -cum ./goroutine | grep returnErr
    done
    sleep 3
  done
}

function get_rancher_goroutine_logs() {
  for pod in $(kubectl get pods -n cattle-system --no-headers -l app=rancher | cut -d ' ' -f1); do
    echo getting goroutine for $pod
    kubectl exec -n cattle-system $pod -- curl -s http://localhost:6060/debug/pprof/goroutine -o goroutine
    kubectl cp cattle-system/${pod}:goroutine ./${pod}-goroutine
    echo saved ${pod}-goroutine
  done
}

function get_cattle_agent_goroutine_logs() {
  for pod in $(kubectl get pods -n cattle-system --no-headers -l app=cattle-cluster-agent | cut -d ' ' -f1); do
    echo getting goroutine for $pod
    kubectl exec -n cattle-system $pod -- curl -s http://localhost:6060/debug/pprof/goroutine -o goroutine
    kubectl cp cattle-system/${pod}:goroutine ./${pod}-goroutine
    echo saved ${pod}-goroutine
  done
}

function pprof_cumulative_errors() {
  # $1 = path to goroutine profile
  go tool pprof "${1}" && top 40 --cum
}
