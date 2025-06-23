#!/bin/bash
set -e

echo "Validating Packer files..."
packer validate -var-file=packer.pkrvars.hcl \
  .

echo "Running build..."
packer build -var-file=packer.pkrvars.hcl \
  .