# AGENT Notes

This file captures the automation and configuration changes added on branch `opencode-lab-scripts`.

## What was added

- Added `lab-run.sh` for end-to-end Kubernetes lab setup and validation.
- Added `lab-cleanup.sh` for teardown of lab resources.
- Added `kind-opencode.yaml` updates for local kind-friendly host port mapping:
  - `10080 -> 80` (ingress HTTP)
  - `10443 -> 443` (ingress HTTPS)

## What was updated

- `Edx-Courses/LFS158x-intro-to-kubernetes/probe.yml`
  - liveness pod image changed to `busybox:1.36` for reliable pulls.
- `Edx-Courses/LFS158x-intro-to-kubernetes/virtual-host-ingress.yaml`
  - migrated from deprecated ingress annotation to `spec.ingressClassName: nginx`.
- `Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server/index.js`
  - default server port changed from `3000` to `13000` (still overrideable via `PORT`).
- `Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server/falcor-express-demo/index.js`
  - default server port changed from `9090` to `19090` (still overrideable via `PORT`).

## `lab-run.sh` behavior highlights

- Performs Kubernetes API preflight check (`kubectl get --raw /version`).
- Supports kubectl versions without `kubectl version --short`.
- Waits for deployment rollout success before continuing.
- Waits for `nginx-pod` and `liveness-exec` readiness.
- Recreates the pod-only demo resources in step 2 to ensure manifest changes are applied.
- Applies ingress only when appropriate:
  - `INGRESS_MODE=auto` (default): apply only if ingress class `nginx` exists.
  - `INGRESS_MODE=true`: always apply.
  - `INGRESS_MODE=false`: skip.
- Prints conflict-safe port-forward suggestions by default:
  - `PF_WEB_PORT=18080`
  - `PF_CANARY_PORT=18083`

## `lab-cleanup.sh` behavior highlights

- Removes all resources created by `lab-run.sh`.
- Safely ignores missing resources/manifests.
- Deletes extra generated services/configmaps and CSR.

## Quick usage

Run lab:

```bash
./lab-run.sh
```

Run with overrides:

```bash
WAIT_TIMEOUT=240s INGRESS_MODE=auto PF_WEB_PORT=18080 PF_CANARY_PORT=18083 ./lab-run.sh
```

Cleanup:

```bash
./lab-cleanup.sh
```
