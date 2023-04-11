This terraform is a collection of root modules for creating downstream RKE, RKE2, and K3s "baseline" clusters to test Rancher's scaling ability. It contains multiple root modules, separated by cluster type (provisioned, imported, custom) and by cloud provider (AWS, Linode). A baseline cluster is essentially any HA (multi-node) cluster that is loaded with a predetermined set of "components" (secrets, projects, namespaces, users, rolebindings, configmaps, etc.).

There are generally 2 "versions" of each module, a "static" one and a "dynamic" one. The static module will create a set of 3 clusters
(RKE, RKE2, K3s) and will load them with a number of components, which will serve as baseline clusters. The dynamic module allows for passing in a list of cluster configs, 1 cluster will be created per config, and each cluster will be loaded with components as well.

### Folder Structure
Each module is separated into one of the following folders: `provisioned/`, `imported/`, or `custom/`. These represent the types of clusters that the underlying modules will create.

Additionally there is a `utils/` directory which contains a number of helpful scripts when testing scalability.
