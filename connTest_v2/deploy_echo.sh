#!/bin/bash


kubectl apply -f ./server/deployment.yaml -n test
kubectl apply -f ./server/echo-server-service.yaml -n test
kubectl apply -f ./client/deployment.yaml -n test
