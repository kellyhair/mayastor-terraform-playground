# AWS kubeadm module

Terraform module for bootstrapping a Kubernetes cluster with kubeadm on AWS.

## Contents

- [**Description**](#description)
- [**Quick start**](#quick-start)
- [**Prerequisites**](#prerequisites)
- [**AWS resources**](#aws-resources)
- [**Network**](#network)

## Description

This module allows to create AWS infrastructure and bootstrap a Kubernetes cluster on it with a single command.

Running the module results in a freshly bootstrapped Kubernetes cluster — like what you get after manually bootstrapping a cluster with `kubeadm init` and `kubeadm join` plus it deploys [flannel](https://github.com/coreos/flannel) as CNI.

The module also creates a kubeconfig file on your local machine so that you can access the cluster right away.

The number and types of nodes and many other parameters are configurable.

Notes:

- For now, the created clusters are limited to a single master node
- When you delete the cluster with `terraform destroy`, the kubeconfig file is currently not automatically deleted, thus you have to clean it up yourself if you don't want to have it sticking around.
- The module also sets up SSH access to the nodes of the cluster. Given one of private keys belonging to `ssh_public_keys` configured is available to your ssh client (probably via ssh agent) you can ssh to any instance using:

```bash
ssh ubuntu@<PUBLIC-IP>
# or
ssh root@<PUBLIC-IP>
```

- The public IP addresses of all the nodes are specified in the output of the module, which you can display with `terraform output`.

## AWS resources

With the default settings (1 master node and 2 worker nodes), the module creates the following AWS resources:

| Explicitly created        | Implicitly created (default sub-resources)                          |
|---------------------------|---------------------------------------------------------------------|
| 4 [Security Groups][sg]   |                                                                     |
| 1 [Key Pair][key]         |                                                                     |
| 1 [Elastic IP][eip]       |                                                                     |
| 3 [EC2 Instances][i]      | 2x3 [Volumes][vol], 3 [Network Interfaces][eni]                     |

[sg]: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html
[eip]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
[i]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html
[vol]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEBS.html
[eni]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html
[key]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

Note that each node results in the creation of 4 AWS resources: 1 EC2 instance, 2 Volumes, and 1 Network Interface. Consequently, you can add or subtract 4 from the total number of created AWS resources for each added or removed worker node.

You can list all AWS resources in a given region with the [Tag Editor](https://console.aws.amazon.com/resource-groups/tag-editor) in the AWS Console.

> Note that [Key Pairs][key] are not listed in the Tag Editor.

### Tags

The module assigns a tag with a key of `kubeadm:cluster` and a value corresponding to the cluster name to all explicitly created resources. For example, if the cluster name is `relaxed-ocelot`, all of the above explicitly created resources will have the following tag:

```
kubeadm:cluster=relaxed-ocelot
```

This allows you to easily identify the resources that belong to a given cluster.

Note that some implicitly created sub-resources (such as Network Interfaces of the EC2 Instances) won't have the `kubeadm:cluster` tag assigned.

Additionally, the EC2 instances will get a tag with a key of `kubeadm:node` and a value corresponding to the Kubernetes node name. For the master node, this is:

```
kubeadm:node=master
```

And for the worker nodes:

```
kubeadm:node=worker-X
```

Where `X` is an index starting at 0.

Additionally, `Name` tag is set on most resources to cluster name except EC2 instances which are named `<cluster name>-<role>` where role is either `master` or `worker-X`.

## Network

The `network.tf` creates a dedicated VPC for your cluster with a single subnet.

### AWS resources

The module creates the following AWS resources:

| Explicitly created        | Implicitly created (default sub-resources)                          |
|---------------------------|---------------------------------------------------------------------|
| 1 [VPC][vpc]              | 1 [Route Table][rtb], 1 [Security Group][sg], 1 [Network ACL][acl]  |
| 1 [Subnet][subnet]        |                                                                     |
| 1 [Internet Gateway][igw] |                                                                     |
| 1 [Route Table][rtb]      |                                                                     |

**Total: 7 resources**

[vpc]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
[acl]: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html
[rtb]: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html
[sg]: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html
[subnet]: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html
[igw]: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html

You can list all AWS resources in a given region with the [Tag Editor](https://console.aws.amazon.com/resource-groups/tag-editor) in the AWS Console.

# Acknowledgements

Module is inspired by [terraform kubeadm module](https://github.com/weibeld/terraform-aws-kubeadm)
