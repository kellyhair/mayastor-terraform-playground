# PaaS level

- kubedb operator - db management
- voyager operator - ingress + letsencrypt
- k8s dashboard available via ingress and `erp_ingress_ip`
- ingress namespace
    - all services requiring ingress should be put to ingress namespace via ExternalService from its own namespace
