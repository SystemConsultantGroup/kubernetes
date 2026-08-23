[한국어](README.md) | English

# example

This managed application deploys the minimal Node.js service from
[`SystemConsultantGroup/kubernetes-example`](https://github.com/SystemConsultantGroup/kubernetes-example).
It exposes `example.scg.sh` and runs its `/readyz` probe on port 8080.

Production, testing, and preview locks use an immutable source commit and
container digest. The shared application chart creates the corresponding
Deployment and Service for the `fe` workload.

The application exercises Vault integration in every environment. The response
exposes only five selected environment variables so their generated secret
behavior can be inspected without returning the complete process environment.

The non-sensitive example values demonstrate isolation and preview layering:

| Variable | Production | Testing | Preview result |
| --- | --- | --- | --- |
| `EXAMPLE_MESSAGE` | `Hello from production` | `Hello from testing` | `Hello from preview` |
| `ENVIRONMENT` | `production` | `testing` | `preview` |
| `INHERITED_VALUE` | `production-independent` | `inherited-from-testing` | `inherited-from-testing` |
| `OVERRIDDEN_VALUE` | `production` | `testing-base` | `preview-override` |
| `PREVIEW_ONLY_VALUE` | unset | unset | `only-from-preview` |

Preview reads the testing path first and its preview path second. It therefore
inherits `INHERITED_VALUE`, overrides three values, and adds
`PREVIEW_ONLY_VALUE`.
