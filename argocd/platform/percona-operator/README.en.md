[한국어](README.md) | English

# Percona PXC Operator

This platform component installs Percona Operator for MySQL based on Percona
XtraDB Cluster. The Helm chart and operator are pinned to version 1.20.0.

The operator runs in `mysql` and watches only that namespace. The PXC cluster is
a separate Argo CD Application so its custom resource, credentials, storage, and
backup policy can be reviewed independently. This Application's root resource
is excluded from automated pruning to prevent removing the operator and its
CRDs through an accidental Git deletion.

The operator does not create a database by itself and this directory contains no
credentials. Database, operator, and backup credentials must come from reviewed
namespaced External Secrets resources or another approved workflow.

The root Application creates this child at sync wave 2, after local storage at
wave 1. The future PXC Application must use a later wave and must not create a
claim until Argo CD has reconciled the `/var/mnt/data` local provisioner path.

Do not remove the operator or its CRDs while any PXC custom resource exists.
Render and inspect the pinned chart before version changes, then upgrade the
operator separately from PXC database version changes.
