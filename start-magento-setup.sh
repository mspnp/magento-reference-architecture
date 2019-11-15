#!/bin/sh

MAGENTO_COMPOSER_USERNAME=""
MAGENTO_COMPOSER_PASSWORD=""

MYSQL_HOSTNAME=""
MYSQL_USERNAME=""
MYSQL_PASSWORD=""

MAGENTO_RESOURCE_GROUP=""
MAGENTO_RESOURCE_GROUP_LOCATION=""

AZURE_CONTAINER_REGISTRY=""

DISK_SIZE_IN_GB=10

docker run -it --rm mysql mysql -h${MYSQL_HOSTNAME} -u${MYSQL_USERNAME} -p${MYSQL_PASSWORD} -e "drop database if exists magento2; create database magento2;"

SETUP_DISK_ID=$(az disk create --resource-group ${MAGENTO_RESOURCE_GROUP} --location ${MAGENTO_RESOURCE_GROUP_LOCATION} --name magento-disk --size-gb ${DISK_SIZE_IN_GB} --query id --output tsv)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: magento-disk
spec:
  capacity:
    storage: ${DISK_SIZE_IN_GB}Gi
  storageClassName: ""
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  azureDisk:
    kind: Managed
    diskName: magento-disk
    diskURI:  ${SETUP_DISK_ID}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: magento-disk
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${DISK_SIZE_IN_GB}Gi
---
kind: Service
apiVersion: v1
metadata:
  name: magentoweb
spec:
  type: LoadBalancer
  selector:
    app: magentoweb
  ports:
  - port: 80
    name: magentowebport
EOF
kubectl run -i --rm --tty magento-setup --overrides='
{
    "apiVersion": "v1",
    "kind": "Pod",
    "spec": {
        "containers": [
            {
                "name": "magento-init",
                "env": [
                    {
                        "name": "MAGENTO_COMPOSER_USERNAME",
                        "value": "'"${MAGENTO_COMPOSER_USERNAME}"'"
                    },
                    {
                        "name": "MAGENTO_COMPOSER_PASSWORD",
                        "value": "'"${MAGENTO_COMPOSER_PASSWORD}"'"
                    }
                ],
                "image": "'"${AZURE_CONTAINER_REGISTRY}/magento-setup:latest"'",
                "imagePullPolicy": "Always",
                "resources": {
                    "requests": {
                        "memory": "4Gi"
                    }
                },
                "stdin": true,
                "stdinOnce": true,
                "tty": true,
                "volumeMounts": [
                    {
                        "name": "magento-disk",
                        "mountPath": "/var/www/html"
                    }
                ]
            }
        ],
        "imagePullSecrets": [
            {
                "name": "mytestmagentocrcred"
            }
        ],
        "volumes": [
            {
                "name": "magento-disk",
                "persistentVolumeClaim": {
                    "claimName": "magento-disk"
                }
            }
        ]
    }
}
'  --image=${AZURE_CONTAINER_REGISTRY}/magento-setup:latest --image-pull-policy=Always --restart=Never