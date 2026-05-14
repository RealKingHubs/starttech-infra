#!/bin/bash

set -e

cd terraform

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve