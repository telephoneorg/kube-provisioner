#!/bin/bash

# # to reset
# wipefs --all --force /dev/sda5

# rm -rf /var/lib/heketi/*
# rm -rf /etc/glusterfs/*
# rm -rf /var/log/glusterfs/*
# rm -rf /var/lib/glusterfs/*

# ref: https://github.com/kubernetes/kubernetes/tree/master/examples/experimental/persistent-volume-provisioning

kubectl create -f - <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: heketi-system
EOF

kubectl create -f - <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: heketi
  namespace: heketi-system
EOF

for host in saturn jupiter pluto; do
    echo -e '{
    "kind": "Deployment",
    "apiVersion": "extensions/v1beta1",
    "metadata": {
        "name": "glusterfs-<hostname>",
        "namespace": "heketi-system",
        "labels": {
            "glusterfs": "deployment",
            "glusterfs-node": "<hostname>"
        },
        "annotations": {
            "description": "GlusterFS container deployment template",
            "tags": "glusterfs"
        }
    },
    "spec": {
        "replicas":1,
        "template": {
            "metadata": {
                "name": "glusterfs",
                "namespace": "heketi-system",
                "labels": {
                    "name": "glusterfs",
                    "glusterfs": "pod",
                    "glusterfs-node": "<hostname>"
                }
            },
            "spec": {
                "nodeSelector": {
                    "kubernetes.io/hostname": "<hostname>"
                },
                "hostNetwork": true,
                "containers": [
                    {
                        "image": "heketi/gluster:latest",
                        "imagePullPolicy": "Always",
                        "name": "glusterfs",
                        "volumeMounts": [
                            {
                                "name": "glusterfs-heketi",
                                "mountPath": "/var/lib/heketi"
                            },
                            {
                                "name": "glusterfs-run",
                                "mountPath": "/run"
                            },
                            {
                                "name": "glusterfs-lvm",
                                "mountPath": "/run/lvm"
                            },
                            {
                                "name": "glusterfs-etc",
                                "mountPath": "/etc/glusterfs"
                            },
                            {
                                "name": "glusterfs-logs",
                                "mountPath": "/var/log/glusterfs"
                            },
                            {
                                "name": "glusterfs-config",
                                "mountPath": "/var/lib/glusterd"
                            },
                            {
                                "name": "glusterfs-dev",
                                "mountPath": "/dev"
                            },
                            {
                                "name": "glusterfs-cgroup",
                                "mountPath": "/sys/fs/cgroup"
                            }
                        ],
                        "securityContext": {
                            "privileged": true
                        },
                        "readinessProbe": {
                            "timeoutSeconds": 3,
                            "initialDelaySeconds": 60,
                            "exec": {
                                "command": [
                                    "/bin/bash",
                                    "-c",
                                    "systemctl status glusterd.service"
                                ]
                            }
                        },
                        "livenessProbe": {
                            "timeoutSeconds": 3,
                            "initialDelaySeconds": 60,
                            "exec": {
                                "command": [
                                    "/bin/bash",
                                    "-c",
                                    "systemctl status glusterd.service"
                                ]
                            }
                        }
                    }
                ],
                "volumes": [
                    {
                        "name": "glusterfs-heketi",
                        "hostPath": {
                            "path": "/var/lib/heketi"
                        }
                    },
                    {
                        "name": "glusterfs-run"
                    },
                    {
                        "name": "glusterfs-lvm",
                        "hostPath": {
                            "path": "/run/lvm"
                        }
                    },
                    {
                        "name": "glusterfs-etc",
                        "hostPath": {
                            "path": "/etc/glusterfs"
                        }
                    },
                    {
                        "name": "glusterfs-logs",
                        "hostPath": {
                            "path": "/var/log/glusterfs"
                        }
                    },
                    {
                        "name": "glusterfs-config",
                        "hostPath": {
                            "path": "/var/lib/glusterd"
                        }
                    },
                    {
                        "name": "glusterfs-dev",
                        "hostPath": {
                            "path": "/dev"
                        }
                    },
                    {
                        "name": "glusterfs-cgroup",
                        "hostPath": {
                            "path": "/sys/fs/cgroup"
                        }
                    }
                ]
            }
        }
    }
}' | sed "s/<hostname>/${host}.valuphone.com/g" | kubectl create -f -
done

token=$(kubectl get secret --namespace=heketi-system | grep heketi-token | awk '{print $1}')

echo -e '{
  "kind": "Service",
  "apiVersion": "v1",
  "metadata": {
    "name": "heketi",
    "namespace": "heketi-system",
    "labels": {
      "glusterfs": "heketi-service",
      "deploy-heketi": "support"
    },
    "annotations": {
      "description": "Exposes Heketi Service"
    }
  },
  "spec": {
    "selector": {
        "name": "heketi"
    },
    "clusterIP": "172.17.100.50",
    "ports": [
      {
        "name": "admin",
        "port": 8080
      }
    ]
  }
}
{
    "kind": "Deployment",
    "apiVersion": "extensions/v1beta1",
    "metadata": {
        "name": "heketi",
        "namespace": "heketi-system",
        "labels": {
            "glusterfs": "heketi-deployment"
        },
        "annotations": {
            "description": "Defines how to deploy Heketi"
        }
    },
    "spec": {
        "replicas":1,
        "template": {
            "metadata": {
                "name": "heketi",
                "namespace": "heketi-system",
                "labels": {
                    "name": "heketi",
                    "glusterfs": "heketi-pod"
                }
            },
            "spec": {
                "containers": [
                    {
                        "image": "heketi/heketi:dev",
                        "imagePullPolicy": "Always",
                        "name": "heketi",
                        "env": [
                          {
                            "name": "HEKETI_EXECUTOR",
                            "value": "kubernetes"
                          },
                          {
                            "name": "HEKETI_KUBE_USE_SECRET",
                            "value": "y"
                          },
                          {
                            "name": "HEKETI_KUBE_TOKENFILE",
                            "value": "/var/lib/heketi/secret/token"
                          },
                          {
                            "name": "HEKETI_FSTAB",
                            "value": "/var/lib/heketi/fstab"
                          },
                          {
                            "name": "HEKETI_SNAPSHOT_LIMIT",
                            "value": "14"
                          },
                          {
                            "name": "HEKETI_KUBE_INSECURE",
                            "value": "y"
                          },
                          {
                            "name": "HEKETI_KUBE_NAMESPACE",
                            "valueFrom": {
                                "fieldRef": {
                                    "fieldPath": "metadata.namespace"
                                }
                            }
                          },
                          {
                            "name": "HEKETI_KUBE_APIHOST",
                            "value": "https://kubernetes.default"
                          }
                        ],
                        "ports": [
                          {
                            "containerPort": 8080
                          }
                        ],
                        "volumeMounts": [
                          {
                            "name": "db",
                            "mountPath": "/var/lib/heketi"
                          },
                          {
                            "name": "secret",
                            "mountPath": "/var/lib/heketi/secret"
                          }
                        ],
                        "readinessProbe": {
                          "timeoutSeconds": 3,
                          "initialDelaySeconds": 3,
                          "httpGet": {
                            "path": "/hello",
                            "port": 8080
                          }
                        },
                        "livenessProbe": {
                          "timeoutSeconds": 3,
                          "initialDelaySeconds": 30,
                          "httpGet": {
                            "path": "/hello",
                            "port": 8080
                          }
                        }
                      }
                    ],
                    "volumes": [
                      {
                        "name": "db"
                      },
                      {
                        "name": "secret",
                        "secret": {
                          "secretName": "<token>"
                        }
                      }
                ]
            }
        }
    }
}' | sed "s/<token>/$token/" | kubectl apply -f -

pod=$(kubectl get po --namespace=heketi-system | grep heketi | awk '{print $1}')
kubectl port-forward $pod 8080 --namespace=heketi-system &
pf_pid=$!

sleep 3
export HEKETI_CLI_SERVER=http://localhost:8080
curl $HEKETI_CLI_SERVER/hello

cat > topo.json <<'EOF'
{
    "clusters": [
        {
            "nodes": [
                {
                    "node": {
                        "hostnames": {
                            "manage": [
                                "saturn.valuphone.com"
                            ],
                            "storage": [
                                "saturn.valuphone.com"
                            ]
                        },
                        "zone": 1
                    },
                    "devices": [
                        "/dev/sda6"
                    ]
                },
                { 
                    "node": {
                        "hostnames": {
                            "manage": [
                                "jupiter.valuphone.com"
                            ],
                            "storage": [
                                "jupiter.valuphone.com"
                            ]
                        },
                        "zone": 2
                    },
                    "devices": [
                        "/dev/sda5"
                    ]
                },
                {
                    "node": {
                        "hostnames": {
                            "manage": [
                                "pluto.valuphone.com"
                            ],
                            "storage": [
                                "pluto.valuphone.com"
                            ]
                        },
                        "zone": 3
                    },
                    "devices": [
                        "/dev/sda5"
                    ]
                }                      
            ]
        }
    ]
}
EOF

heketi-cli topology load --json=topo.json

heketi-cli setup-openshift-heketi-storage

sed 's/saturn\.valuphone\.com/162.210.195.110/;s/jupiter\.valuphone\.com/162.210.194.99/;s/pluto\.valuphone\.com/162.210.194.107/' heketi-storage.json | kubectl apply -f - --namespace=heketi-system

until [ $(kubectl get job heketi-storage-copy-job -o json --namespace=heketi-system | jq -r '.status.succeeded') = 1 ]; do
    sleep 2
done

kubectl delete all,jobs,deployments,secret --selector="deploy-heketi" --namespace=heketi-system

kubectl create -f - <<'EOF'
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: glusterfs-slow
  annotations:
    storageclass.beta.kubernetes.io/is-default-class: 'true'
provisioner: kubernetes.io/glusterfs
parameters:
  endpoint: heketi-storage-endpoints
  resturl: "http://172.17.100.50:8080"
EOF

# test
kubectl create -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-claim
  annotations:
    volume.beta.kubernetes.io/storage-class: glusterfs-slow
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

sleep 10
kubectl get pv
kubectl get pvc

rm -f heketi-storage.json
rm -f topo.json
