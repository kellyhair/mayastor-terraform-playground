# Deploy Mayastor on Hetzner Cloud

[Hetzner cloud](https://hetzner.cloud) is a **cheap** European cloud provider. Their offerings are nowhere near big public clouds but it is fast and useful for many use-cases. Especially when employing pure-kubernetes deployments w/o hosted postgres and similar solutions.

This repo will create kubernetes cluster using `kubeadm` on [Hetzner cloud](https://hetzner.cloud) and deploy [Mayastor](https://github.com/openebs/Mayastor) there for testing. It uses Hetzner's ceph-based cloud volumes to play with [Mayastor](https://github.com/openebs/Mayastor).

## Prerequisites

### hetzner.cloud project API token with read-write permission

* Create a new [project](https://console.hetzner.cloud/projects) - recommended - allows resource isolation from other possible projects/resources in HCloud.
* _Open project_ `->` _Security_ `->` _API Tokens_ `->` _GENERATE API TOKEN_
* Give it a name, make sure it is _Read & Write token_

### Limits

You need to have ability to create 2+ virtual servers in hetzner cloud. See your [limits](https://console.hetzner.cloud/limits) to verify.

### Terraform

You need to have [terraform](https://www.terraform.io/downloads.html) utility at least version 0.13.

## Usage

Make sure at least one ssh key configured in step 2 below is available via ssh agent.

In top-level directory of this project (not repo!) - the one containing this README:

1. `terraform init`
2. Create `terraform.tfvars` file in the top-level directory with at least following contents (feel free to create more nodes; mayastor will use additional nodes for replication automatically). Update `admin_ssh_keys`. You can also use `key_data` instead of `key_file` to specify key verbatim.

```
hcloud_token     = "<hcloud_r/w_api_token>"
hcloud_csi_token = "<hcloud_r/w_api_token>"

node_count          = 1

admin_ssh_keys = {
    "mykey1": {"key_file": "~/.ssh/id_ed25519.pub"},
}
```
See also `variables.tf`, `modules/k8s/variables.tf` for used defaults e.g. versions and such.


3. `terraform apply`
4. `. ./bin/export-kubeconfig.sh` will export `KUBECONFIG` environment variable so that you can use `kubectl` to connect to your new cluster. Alternatively you can take a look at file printed by `terraform output k8s_admin_conf` for a kubernetes config to use.

If something fails, try to re-run step 3 (and/or fix it & create PR ;-) )

As per [deploy mayastor](https://mayastor.gitbook.io/introduction/quickstart/deploy-mayastor) and [configure mayastor](https://mayastor.gitbook.io/introduction/quickstart/configure-mayastor) documentation please check that all went well:

Make sure all components are up and running:
```
kubectl -n mayastor get pods --selector=app=nats
kubectl -n mayastor get daemonset mayastor-csi
kubectl get pods -n mayastor --selector=app=moac
kubectl -n mayastor get daemonset mayastor
```

Check Mayastor node and pool is up:
```
kubectl -n mayastor get msn
kubectl -n mayastor get msp
```

Now you can play with Mayastor. See [Deploy test application](https://mayastor.gitbook.io/introduction/quickstart/deploy-a-test-application) chapter of Mayastor documentation.

```
kubectl apply -f ./test-pod-fio-mayastor.yaml
```

Wait for a bit for pod `fio-mayastor` to be up:
```
kubectl get pod fio-mayastor
```

and now you can run fio:

```
kubectl exec -it fio-mayastor -- fio --name=benchtest --size=800m --filename=/volume/test --direct=1 --rw=randrw --ioengine=libaio --bs=4k --iodepth=16 --numjobs=1 --time_based --runtime=60
```

For comparison you can run the benchmark directly against hetzner's cloud disk:

```
kubectl apply -f ./test-pod-fio-hcloud-csi.yaml
```

wait for pod to be ready:

```
kubectl get pod fio-hcloud
```

and run the benchmark:

```
kubectl exec -it fio-hcloud -- fio --name=benchtest --size=800m --filename=/volume/test --direct=1 --rw=randrw --ioengine=libaio --bs=4k --iodepth=16 --numjobs=1 --time_based --runtime=60
```

Given that mayastor is a terraform module you can use terraform targeting to destroy and re-create mayastor deployment (possibly with different settings). Just make sure you destroy testing pod & volume before doing so:

```
kubectl delete -f ./test-pod-fio-mayastor.yaml
# [*]
terraform destroy -target=module.mayastor
# tinker about
terraform apply
```

`[*]` for the time being you need to also delete PV
```
kubectl get pv
# ...
kubectl delete pv <pv-id-from-previous-command>
```

### TODO: Examples of playing with various tunables in mayastor

# Architecture

## Module `k8s`

* single master
* configurable amount of worker nodes
* [kubernetes metrics-server](https://github.com/kubernetes-sigs/metrics-server)
* [hcloud_csi](https://github.com/hetznercloud/csi-driver) module to allow provisioning of hetnzer cloud volumes.
* [flannel](https://github.com/coreos/flannel) networking using [wireguard](https://www.wireguard.com/) as transport
* for every node one 10GiB hcloud volume is requested to be used as a mayastor backing device
* given that `k8s` module restarts the machine the module will also reserve hugepages for `mayastor` module that are [hard requirement](https://mayastor.gitbook.io/introduction/quickstart/preparing-the-cluster). According to [kernel hugepages documentation](https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt) it seems that the best way is using kernel commandline to reserve hugepages early during boot process.

Everything will run on Ubuntu 20.04.

## Module mayastor

* uses master branch of mayastor for deploy
* pool is created on every available node
* mayastor storageclass is created with NVMe transport and uses as many replicas as there are nodes

Due to lack of use-cases modules are not made very separable. See [TODO.md](TODO.md) / Wishlist.

# Links

Docker & kubernetes master + nodes installation was inspired by [solidnerd](https://github.com/solidnerd/terraform-k8s-hcloud/).
