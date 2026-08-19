# example

This managed application deploys the minimal Node.js service from
[`SystemConsultantGroup/kubernetes-example`](https://github.com/SystemConsultantGroup/kubernetes-example).
It exposes `example.scg.sh` and runs its `/readyz` probe on port 8080.

Production, testing, and preview locks use an immutable source commit and
container digest. The shared application chart creates the corresponding
Deployment and Service for the `fe` workload.

The application is the non-production Vault integration target. Its generated
Vault paths, policies, and roles use the `example` application identity.
