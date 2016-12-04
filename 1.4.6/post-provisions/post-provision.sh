#!/bin/bash

kubectl create -f assets/configs

kubectl create -f assets/secrets

kubectl create -f assets/ingress-rules
