kubectl get clusters.management.cattle.io
export CLUSTERID="c-m-xxxxxxx" # <-- Add your cluster ID
kubectl patch clusters.management.cattle.io $CLUSTERID -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl delete clusters.management.cattle.io $CLUSTERID


kubectl get Clusters -A
kubectl -n fleet-default patch Clusters <clustername> -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl -n fleet-default delete Clusters <clustername>
