#!/bin/bash
set -e
HOMEOPS_ROOT="$XDG_PROJECTS_DIR/homeops"

echo "Step 1: Ansible -> Provision BIND zones"
cd $HOMEOPS_ROOT/playbooks/opnsense
ansible-playbook -i inventory/hosts.ini main.yml --tags dns

echo "Step 2: Terraform -> Apply DNS records"
cd $HOMEOPS_ROOT/infra/dns
tofu apply -auto-approve
