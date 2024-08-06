#!/bin/bash

PODNAME=${PODNAME}
NAMESPACE=${NAMESPACE}

# 파드 이름과 네임스페이스가 설정되어 있는지 확인
if [[ -z "$PODNAME" || -z "$NAMESPACE" ]]; then
  echo "Usage: POD_NAME=<pod-name> NAMESPACE=<namespace> ./script.sh"
  exit 1
fi

# get pod ip from k8s cluster
POD_IP=$(kubectl get pod $PODNAME -n $NAMESPACE -o jsonpath='{.status.podIP}')

TIMESTAMP=$(date +%m%d%H)
FILENAME="./${TIMESTAMP}_${PODNAME}.pcap"

# execute tcpdump
tcpdump -i any '(src '$POD_IP' or dst '$POD_IP')' -w $FILENAME
