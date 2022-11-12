#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})

. ${SCRIPT_DIR}/../.env

CMD=$1
case $CMD in
apply)
    cat <<EOF | kubectl apply -f -
apiVersion: kpack.io/v1alpha2
kind: ClusterStore
metadata:
  name: default
spec:
  sources:
  - image: gcr.io/paketo-buildpacks/go:3.1.0
---
apiVersion: kpack.io/v1alpha2
kind: ClusterStack
metadata:
  name: base
spec:
  id: io.buildpacks.stacks.bionic
  buildImage:
    image: paketobuildpacks/build:1.2.31-base-cnb
  runImage:
    image: paketobuildpacks/run:1.2.31-base-cnb
---
apiVersion: kpack.io/v1alpha2
kind: ClusterBuilder
metadata:
  name: base
spec:
  tag: ghcr.io/${GITHUB_USERNAME}/kpack/clusterbuilder:base
  serviceAccountName: default
  stack:
    name: base
    kind: ClusterStack
  store:
    name: default
    kind: ClusterStore
  serviceAccountRef:
    name: default
    namespace: default    
  order:
  - group:
    - id: paketo-buildpacks/go
EOF
    ;;

describe)
    (set -x; kubectl describe clusterstore.kpack.io/default)
    (set -x; kubectl describe clusterstack.kpack.io/base)
    (set -x; kubectl describe clusterbuilder.kpack.io/base)
    ;;

show)
    (set -x; kubectl get ClusterStore default)
    (set -x; kubectl get ClusterStack,ClusterBuilder base)
    ;;
esac
