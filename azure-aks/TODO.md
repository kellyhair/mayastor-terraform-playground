[ ] finish terraforming README
[ ] consider building k8s cluster "manually" instead of using MS managed one
[ ] terraform destroy doesn't remove
    - `NetworkWatcher` (multiple times)
    - `aks-vnet-*` (once)
    - removing manually leads to a state when all resources shows them in the list but deleting says it does not exist (and I feel NetworkWatcher is created automatically again when -- nonexistent and undeletable -- `aks-vmnet-*` is shown in all resources
