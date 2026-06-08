# Operations

## Configure script: install, uninstall, and scale

[`scripts/configure.sh`](../scripts/configure.sh) is the main entrypoint for Slurm
lifecycle on the inventory (bare metal or test VMs). It defaults to `install`.

```bash
# Deploy (same as ./scripts/configure.sh with no subcommand)
./scripts/configure.sh install

# Full purge: Slurm, munge, MariaDB, configs, and /etc/hosts entries
./scripts/configure.sh uninstall          # prompts for confirmation

# Scale up: add hosts to slurmexechosts in inventory, then reconcile
./scripts/configure.sh scale

# Scale down: drain nodes first, then purge Slurm on removed hosts only
./scripts/configure.sh scale --remove slurm-dev-compute-02
# Edit inventory to drop those hosts from slurmexechosts, then:
./scripts/configure.sh scale
```

**Scale-down assumptions:** nodes are already drained and have no running jobs.
`scale --remove` does not edit inventory automatically; remove hosts from
`slurmexechosts` in `build/hosts.yml` or your static inventory, then run
`scale` again to regenerate `slurm.conf` on the cluster.

Uninstall removes only Slurm software. It does not destroy DigitalOcean droplets
(use `./scripts/destroy.sh`) or unmount the shared NFS share.

## Running individual Ansible playbooks

Run from the `ansible/` directory so `ansible.cfg` resolves the inventory
(`./inventory` for group vars + `../build/hosts.yml` for hosts):

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml -p collections
ansible-galaxy role install -r requirements.yml -p roles

ansible all -m ping
ansible-playbook playbooks/slurmdbd.yml
ansible-playbook playbooks/slurm.yml
ansible-playbook playbooks/uninstall.yml   # full purge; use -e purge_db=false for partial
```

Slurmdbd host variables live in
[`inventory/group_vars/slurmdbdservers.yml`](../ansible/inventory/group_vars/slurmdbdservers.yml).
If `slurmdbd` fails to parse its config, see
[ansible-slurm.md](ansible-slurm.md#known-issue-slurmctldpidfile-in-slurmdbdconf).
