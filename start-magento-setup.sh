#!/bin/sh

docker run -it --rm mysql mysql -hmytestmagentodb.mysql.database.azure.com -uaoakley@mytestmagentodb -p"Ehe5Mb42S%nBoK*c" -e "drop database if exists magento2; create database magento2;"

SETUP_DISK_ID=$(az disk create --resource-group my-test-magento-rg --location centralus --name magento-disk --size-gb 10 --query id --output tsv)

kubectl run -i --rm --tty magento-setup --overrides='
{
    "apiVersion": "v1",
    "kind": "Pod",
    "spec": {
        "containers": [
            {
                "name": "magento-init",
                "image": "mytestmagentocr.azurecr.io/magento-setup:latest",
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
                "azureDisk": {
                    "kind": "Managed",
                    "diskName": "magento-disk",
                    "diskURI": "'"$SETUP_DISK_ID"'"
                }
            }
        ]
    }
}
'  --image=mytestmagentocr.azurecr.io/magento-setup:latest --image-pull-policy=Always --restart=Never