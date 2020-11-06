# Deploy Mayastor on Azure AKS

AKS is a managed k8s service on Azure so we don't have to manage k8s service
ourselves, but Azure does that for us. All we need to do is create the worker
nodes and configure them correctly. Unfortunately we cannot do that by just
using Terraform as of now so we use a hybrid approach of using terraform
and then using az CLI and kubectl to configure the rest. There are a couple
of reasons why using Terraform for the whole process is not possible:

* Terraform `azurerm_kubernetes_cluster` resource does not expose ID of
  created vmss (VM scale-set).
* Any customization of vmss like setting custom-script extension configure
  hugepages applies only to newly spawned nodes so when we change the
  configuration of vmss we need to scale vmss to zero and then back to
  required number of workers.
* There can be only one vmss extension of custom-script type. Since kubernetes
  configures vmss with custom-script extension that runs `kubeadm join` like
  task we cannot add more custom-scripts to it. That's the reason why hugepages
  are configured by sshing to nodes that is complicated to do rather than by
  using `az vmss extension set` command.

## Prerequisities

* azure account (can be a free account with a free credit valid for one month)
* installed `az` CLI tool and run `az login` to configure access to Azure
* installed `terraform` at least 0.13 version
* jq json processing utility

## Steps

1.  `terraform init`
2.  Create a cluster without workers: `terraform apply`
3.  Save kube-config to local file: `terraform output kube_config >kubeconfig` and `export KUBECONFIG=$PWD/kubeconfig`
4.  Check that the cluster exists: `kubectl cluster-info`
5.  Get name of the resource group: `export RESOURCE_GROUP=$(az group list --tag=Environment=Test | jq -r '.[0].name' )`
6.  Get name of the created vmss: `export VMSS_NAME=$(az vmss list --resource-group $RESOURCE_GROUP | jq -r '.[0].name' )`
7.  Attach 1G data disk to each worker: `az vmss disk attach --vmss-name $VMSS_NAME --resource-group $RESOURCE_GROUP --size-gb 1`
8.  Update vmss with the new settings: `az vmss update --name $VMSS_NAME --resource-group $RESOURCE_GROUP`
9.  Scale down vmss to zero: `az vmss scale --name $VMSS_NAME --new-capacity 0 --resource-group $RESOURCE_GROUP`
10. Check that there are no VMs in vmss: `az vmss list-instances --name $VMSS_NAME --resource-group $RESOURCE_GROUP`
11. Scale vmss to required number of workers: `az vmss scale --name $VMSS_NAME --new-capacity 2 --resource-group $RESOURCE_GROUP`
12. Check workers and note the private IP address of each: `kubectl get nodes -o wide`
14. Set up ssh trampoline: `kubectl run -it --rm aks-ssh --image=debian` and run following command in it `apt-get update && apt-get install openssh-client -y`
15. From another window: copy your private key to ssh trampoline: `kubectl cp ~/.ssh/id_rsa $(kubectl get pod -l run=aks-ssh -o jsonpath='{.items[0].metadata.name}'):/id_rsa`
16. In ssh trampoline window run: `chmod 0600 id_rsa`
17. Connect to each worker using its private IP address from the ssh trampoline container: `ssh -i id_rsa mayastor@X.Y.Z.V` and configure hugepages:
    a. `echo 512 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages`
    b. `sudo systemctl restart kubelet` (this can disconnect ssh trampoline if running on the same node)
18. Continue with normal deploy steps for Mayastor. Data disk on storage nodes is `/dev/sdc`.

You get charged for running VMs, storage, etc. To destroy the whole cluster
run: `terraform destroy`.

## TODO

* Figure out how to do fully terraform without `az` commands and ssh trampoline.

## Links

* [Documentation of azure terraform provider](https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html)
* [How to connect to workers using SSH](https://docs.microsoft.com/en-us/azure/aks/ssh#:~:text=You can access AKS nodes,use the private IP address.)
* [az CLI reference](https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest)
