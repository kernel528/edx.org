# edx.org Course Labs

This repository contains hands-on learning materials and demos from edX/Linux Foundation coursework.

## Main course folders

- `Edx-Courses/LFS141x-exploring-graphql/`
  - Falcor/Express demos and React sandbox examples.
- `Edx-Courses/LFS158x-intro-to-kubernetes/`
  - Kubernetes manifests for deployments, services, canary, blue/green, probes, config, RBAC, and ingress.

## Lab automation scripts (added)

- `lab-run.sh`
  - End-to-end apply + validation flow for the Kubernetes lab.
  - Includes rollout/readiness checks and cluster preflight validation.
  - Ingress apply behavior is controlled with `INGRESS_MODE=auto|true|false`.
- `lab-cleanup.sh`
  - Removes resources created by `lab-run.sh`.

## Local kind cluster config

- `kind-opencode.yaml`
  - Local kind cluster profile used for this lab.
  - Includes host port mappings to avoid common conflicts:
    - `10080 -> 80`
    - `10443 -> 443`

## Important updates in manifests/apps

- `Edx-Courses/LFS158x-intro-to-kubernetes/probe.yml`
  - Uses `busybox:1.36` for liveness probe pod image.
- `Edx-Courses/LFS158x-intro-to-kubernetes/virtual-host-ingress.yaml`
  - Uses `spec.ingressClassName: nginx` (modern ingress style).
- Falcor demo port defaults were moved to conflict-safe values:
  - `.../falcor-app-server/index.js` defaults to `13000`
  - `.../falcor-express-demo/index.js` defaults to `19090`

## Quick start

Create cluster:

```bash
kind create cluster --config kind-opencode.yaml
```

Run the Kubernetes lab:

```bash
./lab-run.sh
```

Optional override example:

```bash
PF_WEB_PORT=18080 PF_CANARY_PORT=18083 ./lab-run.sh
```

Cleanup:

```bash
./lab-cleanup.sh
```

## Notes

- If no ingress controller is installed, `lab-run.sh` (default `INGRESS_MODE=auto`) will skip ingress apply.
- See `AGENT.md` for a focused summary of branch automation/config updates.
