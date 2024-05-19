#!/bin/bash

if [ -z "$HUB" ] || [ -z "$TAG" ]; then
    echo "Error: Missing arguments. Please provide the TAG name and HUB."
    exit 1
fi

set -e 

make build


HUB=$HUB TAG=$TAG make docker.pilot
HUB=$HUB TAG=$TAG make docker.proxyv2

docker push $HUB/pilot:$TAG 
docker push $HUB/proxyv2:$TAG

yes | istioctl uninstall --purge

envsubst < ./istiod_manifests_boan/custom_istio_debug.yaml > ./istiod_manifests_boan/custom_istio_debug_temp.yaml

yes | istioctl install -f ./istiod_manifests_boan/custom_istio_debug_temp.yaml  --log_output_level=debug

rm ./istiod_manifests_boan/custom_istio_debug_temp.yaml

kubectl get pods -n istio-system 

istioctl dashboard controlz deployment/istiod.istio-system


