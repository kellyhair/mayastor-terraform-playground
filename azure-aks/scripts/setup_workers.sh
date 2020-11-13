#! /bin/sh

set -eux

# FIXME use wait instead of loops e.g. for vm: https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az_vm_wait

if [ -z "$KUBECONFIG" ]; then
	echo "Script requires KUBECONFIG to be set" >&2
	exit 1
fi

resource_group=null
while [ "$resource_group" = "null" ]; do
	resource_group=$(az group list --tag=environment="$ENVIRONMENT" | jq -r '.[0].name')
	sleep 3
done
vmss_name=null
while [ "$vmss_name" = "null" ]; do
	vmss_name=$(az vmss list --resource-group "$resource_group" | jq -r '.[0].name')
	sleep 3
done
# FIXME: not idempotent
az vmss disk attach --vmss-name "$vmss_name" --resource-group "$resource_group" --size-gb 1 > /dev/null
az vmss update --name "$vmss_name" --resource-group "$resource_group" > /dev/null
az vmss scale --name "$vmss_name" --new-capacity 0 --resource-group "$resource_group" > /dev/null
# wait for scale down (is this required? it seems az vmss scale is synchronous and scale down is done when api call finishes ...
while [ "$(az vmss list-instances --name "$vmss_name" --resource-group "$resource_group" | jq '. | length')" != '0' ]; do
	sleep 3
done
az vmss scale --name "$vmss_name" --new-capacity "$NUM_WORKERS" --resource-group "$resource_group" > /dev/null
# wait for scale up
while [ "$(az vmss list-instances --name "$vmss_name" --resource-group "$resource_group" | jq '. | length')" = '0' ]; do
	sleep 3
done

