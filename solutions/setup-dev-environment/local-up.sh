#!/bin/bash

cd $(dirname ${BASH_SOURCE})

set -e

hub=${CLUSTER1:-hub}
c1=${CLUSTER1:-cluster1}
c2=${CLUSTER2:-cluster2}

hubctx="kind-${hub}"
c1ctx="kind-${c1}"
c2ctx="kind-${c2}"

kind create cluster --name "${hub}"
if [[ "${hub}" != "${c1}" ]]; then
  kind create cluster --name "${c1}"
fi
kind create cluster --name "${c2}"

kubectl config use ${hubctx}
echo "Initialize the ocm hub cluster"
joincmd=$(clusteradm init --use-bootstrap-token | grep clusteradm)

kubectl config use ${c1ctx}
echo "Join cluster1 to hub"
$(echo ${joincmd} | sed "s/<cluster_name>/$c1/g")

kubectl config use ${c2ctx}
echo "Join cluster2 to hub"
$(echo ${joincmd} | sed "s/<cluster_name>/$c2/g")

kubectl config use ${hubctx}
echo "Accept join of cluster1 and cluster2"
clusteradm accept --clusters ${c1},${c2}

kubectl label managedcluster ${c1} name=${c1}
kubectl label managedcluster ${c2} name=${c2}
kubectl label managedcluster ${c2} cluster.open-cluster-management.io/clusterset=clusterset1

clusteradm install addons --names application-manager
clusteradm enable addons --names application-manager --clusters ${c1}
clusteradm enable addons --names application-manager --clusters ${c2}

cd ~/Playground/application
make deploy
