#!/bin/sh

DISK_SIZE_IN_GB=10
NUMBER_OF_PODS=3

# First, we will clean up everything just in case we are resizing the number of pods or recreating the snapshot

# Delete all web pods
kubectl delete pods -l type=magento-pods
kubectl wait --for delete pod -l type=magento-pods

# Delete all persistent volumes and persistent volume claims
kubectl delete persistentvolumeclaims -l type=magento-disks
kubectl wait --for delete persistentvolumeclaims -l type=magento-disks

kubectl delete persistentvolumes -l type=magento-disks
kubectl wait --for delete persistentvolumes -l type=magento-disks

# Delete all of the Disk resources
while IFS= read -r RESOURCE_ID; do
  az disk delete --ids $RESOURCE_ID --yes
done <<EOF
$(az disk list --resource-group my-test-magento-rg --query "[?starts_with(name, 'magentoweb-pv-')].id" --output tsv)
EOF

RESOURCE_ID=$(az snapshot show --resource-group my-test-magento-rg --name magento-disk-snapshot --query id --output tsv)
if [ ! -z "$RESOURCE_ID" ]; then
  az snapshot delete --resource-group my-test-magento-rg --name magento-disk-snapshot
fi

az snapshot create --resource-group my-test-magento-rg --name magento-disk-snapshot --source /subscriptions/3b518fac-e5c8-4f59-8ed5-d70b626f8e10/resourceGroups/my-test-magento-rg/providers/Microsoft.Compute/disks/magento-disk

i=0 # Number of pods/disks to create
while [ $i -le $(( $NUMBER_OF_PODS - 1 )) ]; do
  POD_NAME="magentoweb-${i}"
  POD_DISK_NAME="magentoweb-pv-${i}"
  RESOURCE_ID=$(az disk show --resource-group my-test-magento-rg --name ${POD_DISK_NAME} --query id --output tsv)
  #if [ ! -z "$RESOURCE_ID" ]; then
  #  az disk delete --resource-group my-test-magento-rg --name ${POD_DISK_NAME} --yes
  #fi
  POD_DISK_ID=$(az disk create --resource-group my-test-magento-rg --name ${POD_DISK_NAME} --source magento-disk-snapshot --query id --output tsv)
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${POD_DISK_NAME}
  labels:
    type: magento-disks
spec:
  capacity:
    storage: ${DISK_SIZE_IN_GB}Gi
  storageClassName: ""
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  azureDisk:
    kind: Managed
    diskName: ${POD_DISK_NAME}
    diskURI:  ${POD_DISK_ID}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${POD_DISK_NAME}
  labels:
    type: magento-disks
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${DISK_SIZE_IN_GB}Gi
---
kind: Pod
apiVersion: v1
metadata:
  name: ${POD_NAME}
  namespace: default
  labels:
    app: magentoweb
    type: magento-pods
spec:
  containers:
  - image: mytestmagentocr.azurecr.io/magento:latest
    imagePullPolicy: Always
    name: magentoweb
    ports:
    - containerPort: 80
      protocol: TCP
    resources:
      requests:
        memory: "4Gi"
    volumeMounts:
    - name: ${POD_DISK_NAME}
      mountPath: /var/www/html
  imagePullSecrets:
  - name: mytestmagentocrcred
  volumes:
  - name: ${POD_DISK_NAME}
    persistentVolumeClaim:
      claimName: ${POD_DISK_NAME}
EOF
  i=$(( i + 1 ))
done
