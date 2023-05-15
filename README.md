# rancher2-scaling

Terraform for running control plane and downstream clusters
Python for scaling tests


## Root Modules
* `control-plane`: for getting Rancher running
* `clusters`: for scaling Rancher with many clusters
* `cluster-with-nodes`: for scaling Rancher with many nodes per cluster

## Convenience Modules
* `rancher-cluster-operations`: a collection of convenience modules for creating various rancher2 resources that are commonly used

## Prerequisites
- [Terraform](https://www.terraform.io/)
- [Kubectl](https://www.terraform.io/)

## Recommended Dev Tools
- [pre-commit](https://pre-commit.com/#install)
  - [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks)
  - [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
---
### Setup Recommended pre-commit Hooks
1. Install `pre-commit`
2. Create `pre-commit-config.yaml` in the git working directory of this repository
3. Add `pre-commit-hooks` to your `pre-commit-config.yaml`
   - Example recommended `pre-commit-config.yaml` configuration:
        ```
        repos:
        - repo: https://github.com/pre-commit/pre-commit-hooks
            rev: v4.2.0
            hooks:
            - id: detect-aws-credentials
            - id: detect-private-key
            - id: check-yaml
            - id: trailing-whitespace
        ```
4. Add `pre-commit-terraform` hooks to your `pre-commit-config.yaml`:
   - Example recommended `pre-commit-terraform` configuration:
        ```
        ...
        - repo: https://github.com/antonbabenko/pre-commit-terraform
            rev: v1.72.1
            hooks:
            - id: terraform_tflint
                args:
                - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl # this file needs to exist at this path
                - --args=--enable-rule=terraform_comment_syntax
                - --args=--enable-rule=terraform_naming_convention
                - --args=--enable-rule=terraform_deprecated_index
                - --args=--enable-rule=terraform_deprecated_interpolation
            - id: terraform_fmt
                args:
                - --args=-recursive
            - id: terraform_docs
                args:
                - --hook-config=--path-to-file=README.md # Valid UNIX path. I.e. ../TFDOC.md or docs/README.md etc.
                - --hook-config=--add-to-existing-file=true # Boolean. true or false
                - --hook-config=--create-file-if-not-exist=true # Boolean. true or false
        ```
5. Create a `.tflint.hcl` configuration in the git working directory of this repository
6. Add the desired `tflint` configuration to the `.tflint.hcl` file
   - Example recommended `.tflint.hcl` configuration:
        ```
        config {
            plugin_dir = "~/.tflint.d/plugins"
            module = true
            force = false
            disabled_by_default = false
        }

        plugin "aws" {
            enabled = true
            version = "0.13.4"
            source  = "github.com/terraform-linters/tflint-ruleset-aws"
            deep_check = false
        }

        ```

### Upgrading Provider Versions
As new versions of providers are released it may be necessary to upgrade module provider dependencies, conversely it might be necessary to lock providers to a specific version for a given module. In order to facilitate this, version constraints should be placed on each module's providers as needed.

Additionally, versions should only be explicitly upgraded when the changes have been reviewed and any necessary module compatibility changes have been made to support the new provider versions.

In order to upgrade provider versions, you should first modify the version constraint for a given provider to include the new version you wish to use. Then proceed to run the following command on the module: `terraform init -upgrade`, this command will upgrade all providers to the latest version that is consistent with the version constraints specified.

After upgrading provider versions you should run a provider lock with explicit platform support to ensure other developers will be able to make use of the exact versions that were upgraded. Here is an example: `terraform providers lock -platform=linux_amd64 -platform=darwin_amd64 -platform=windows_amd64 -platform=linux_arm64 -platform=darwin_arm64`, this bundles the provider checksums for linux, darwin and windows on `amd64` and linux and darwin on `arm64`.
