#!/usr/bin/env bash

#set the path for the kubeconfig
export KUBECONFIG="/home/ivln/workspace/work/RancherVCS/rancher2-scaling/rke1-local-control-plane/files/clusters/medium-rke1-1.26-2.7.5/kube_config_medium-rke1-1.26-2.7.5_cluster.yml"

#kubectl api-resoruces call lists all resources, loop on each resource
for resource in $(kubectl api-resources -o wide | grep true | awk '{ print $1 }');
    do
        #output the resource name
        echo -n " ${resource} : "
        #kubeclt get call on each resoruce for all namespaces, loop and count lines ignoring column title lines
        for count in $(kubectl get $resource -A | grep -v "NAMESPACE" | grep -v "NAME" | wc -l);
            do
                #remove counts of 0 to improve outputs on absent resources
                echo "${count}" | grep -v -x "0"
    done
done
