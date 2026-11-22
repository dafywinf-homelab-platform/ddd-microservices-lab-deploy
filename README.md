# ddd-microservices-lab-deploy

Deployment configuration for [ddd-microservices-lab](https://github.com/dafywinf/ddd-microservices-lab): which
release of each service runs in each environment, and the infrastructure they need. Argo CD deploys this repo to the
homelab k3s cluster; Renovate keeps the versions current.

How releases are made and reach this repo: [Release and delivery](https://github.com/dafywinf/ddd-microservices-lab/blob/main/docs/release-and-delivery.md).

## Layout

```
charts/spring-service/        one shared Helm chart for every service: Deployment, Service, Ingress, ServiceMonitor
environments/sit/
  order-service.yaml          values per service: image (version@digest), port, settings, resources, ingress host
  inventory-service.yaml
  infra/                      MongoDB 9.0.8 (single-node replica set) and Redpanda v26.3.1, plain manifests
argocd/sit/                   the Argo CD Applications for SIT: infra (wave -1) and one per service
renovate.json                 new service releases are merged into SIT automatically
.github/workflows/validate.yml  renders every environment and checks it against the Kubernetes and CRD schemas
```

## SIT

| | |
|---|---|
| Namespace | `ddd-microservices-lab-sit` |
| order-service | https://order-service-sit.192-168-86-10.sslip.io |
| inventory-service | https://inventory-service-sit.192-168-86-10.sslip.io |
| Argo CD | `ddd-microservices-lab-sit` (app-of-apps, defined in homelab-gitops) → `-infra`, `-order-service`, `-inventory-service` |
| Memory requests | ~1.75 GiB: services 384 Mi each, Redpanda 768 Mi, Mongo 256 Mi |

`ddd-microservices-lab-sit` has **no automatic sync**. Syncing it once in Argo CD creates the three child
Applications, which do sync automatically from then on.

## How a release reaches SIT

1. ddd-microservices-lab publishes `ghcr.io/dafywinf/<service>:<version>` after each release.
2. Renovate sees the new tag and opens a PR here that changes `image.tag` to `<version>@sha256:<digest>`.
3. **Validate** runs on the PR; when it passes, Renovate merges it (minor and patch releases; majors wait for
   approval in the Dependency Dashboard issue).
4. Argo CD sees the change on `main` (it polls every 3 minutes) and rolls out the new version.

## Common tasks

**Deploy a release now, without waiting for Renovate:** open the Dependency Dashboard issue and tick the update, or
edit `image.tag` in `environments/sit/<service>.yaml` yourself (version and digest).

**Roll back:** set `image.tag` back to the earlier version and digest. Renovate would offer the newer release again
straight away, so also stop it: add the bad version to a `packageRules` entry with `"allowedVersions": "!/^1\\.4\\.2$/"`,
or close Renovate's PR (closed PRs for a version are not recreated).

**Add a service:** add `environments/sit/<service>.yaml` and `argocd/sit/<service>.yaml` (copy an existing pair).

**Check locally before pushing:**

```sh
helm template order-service charts/spring-service -f environments/sit/order-service.yaml
```
