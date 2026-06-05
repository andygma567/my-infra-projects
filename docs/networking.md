# Networking: the VPC is referenced, not managed

`tofu/main.tf` does **not** create a VPC. Instead it looks up the region's
existing **default** VPC via a data source:

```hcl
data "digitalocean_vpc" "slurm_vpc" {
  region = var.region
}
```

This is deliberate. DigitalOcean requires exactly one **default VPC per region**
and **default VPCs cannot be deleted** (`403 Can not delete default VPCs`). A
dedicated VPC created by `apply` gets auto-promoted to the region default when no
other default exists, which then breaks the disposable lifecycle in two ways:

- **`destroy` fails** with `403 ... Can not delete default VPCs`, and
- after dropping it from state, the **next `apply` fails** with
  `422 ... a VPC with the same name already exists`.

Referencing the always-present default VPC sidesteps both: the droplets and NFS
share are placed in it, but `apply` never creates it and `destroy` never deletes
it. Trade-off: the test nodes share the region's default VPC rather than a
dedicated isolated network with a custom IP range — fine for disposable test
scaffolding.

> **Migrating from the old resource-based config?** If a previous version managed
> `digitalocean_vpc.slurm_vpc`, drop it from state once (this only edits local
> state; the VPC itself is untouched and stays as the free region default):
>
> ```bash
> cd tofu
> tofu state rm digitalocean_vpc.slurm_vpc   # ignore if it's already absent
> ```
>
> VPCs live under **Networking → VPC** in the DO console (not the **Domains** tab).
