# Terraform for Mayastor

This repo contains an experimental implementation of Terraform scripts for installing Mayastor to Kubernetes running on different cloud providers. Content will be eventually merged into Mayastor main repository.

Content is *highly unstable*. Please, don't use in production.

Status:
- Hetzner Cloud is working
- AWS in progress
- Azure postponed at the moment

You can also run checks locally with `act -P ubuntu-latest=node:12.6-buster` using [`act`](https://github.com/nektos/act).
