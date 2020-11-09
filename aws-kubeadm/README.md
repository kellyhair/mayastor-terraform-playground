# kubeadm cluster in AWS

We make use of the existing
[terraform kubeadm module](https://github.com/weibeld/terraform-aws-kubeadm)
for AWS. It creates the necessary infrastructure including VMs and then uses
kubeadm to initialize and configure the cluster. About the module:

* The module has a limitation that does not allow us to attach EBS volume to
  worker nodes. Discussed in greater detail
  [here](https://github.com/weibeld/terraform-aws-kubeadm/issues/5). It will
  be fixed in the next version of the module. Until then we have a fixed copy
  of the module in our source code tree.
* The module does not install any CNI plugin. We install kube-router CNI plugin.
* Routing between pods is broken so core-dns pods and moac cannot reach k8s
  api server.

## Prerequisities

* aws account
* installed and configured `aws` CLI tool (`aws configure`)
* installed `terraform` at least 0.13 version

## Steps

1. `terraform init`
2. `terraform apply`
3. Terraform will create a kubeconfig file for you in the working directory
   with the same name as your cluster name (i.e. emerging-gannet.conf). In
   order to use it with kubectl type
   `export KUBECONFIG=$PWD/emerging-gannet.conf` (replace the name with yours).
4. Check that the cluster exists: `kubectl cluster-info`
5. Use public IP info displayed in aws management console to ssh to worker
   nodes and configure hugepages and restart kubelet.
6. Continue with normal deploy steps for Mayastor.

To destroy the whole cluster run: `terraform destroy`.

## TODO

* Remove kubeadm module when it is fixed in the new version.
* Fix routing between the pods (Hint: compare to a cluster set up by kops and
  spot the difference).

