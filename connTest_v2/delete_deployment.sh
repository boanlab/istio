#!/bin/bash

kubectl delete deployment echo-server -n test
kubectl delete deployment echo-client -n test
