#!/bin/bash

# cfssl gencert -initca ca-csr.json | cfssljson -bare ca

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=etcd \
  etcd-csr.json | cfssljson -bare etcd

# chmod 0600 *-key.pem
