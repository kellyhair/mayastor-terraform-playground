# CI

[x] terraform fmt, validate
[ ] shellcheck
[ ] yamllint
[ ] [checkov](https://github.com/bridgecrewio/checkov)
[ ] symlink shared modules (i.e. mayastor deploy) - or rather use one top-level terraform and select cloud using variables? (as windows users will have problems with symlinks)

# mayastor

- install mayastor client for people to play with

# terraform

- split pure cluster install, mayastor dependencies install (nvme-tcp, hugepages, volumes for mayastor,...?) and mayastor install itsef
    - make installation of modules configurable via variables
- add installation of test pod for people to immediately play with
- add ability to run test pod (fio benchmark) directly on backing device to have quick comparison
    [x] hcloud
- share modules between different cloud installs properly
    - publish to terraform registry?

# checkov / triat

We have tested integrating checkov into CI pipeline, but decided to postpone it as it will need more fine-tuning.

```
      - name: Security Scan via checkov
        id: checkov
        uses: bridgecrewio/checkov-action@master

      - name: Security Scan via Triat
        uses: triat/terraform-security-scan@master
```
