# Repository Guidelines

## Project Structure & Module Organization
This repository stores EdX course artifacts, not a single deployable app.

- `Edx-Courses/LFS158x-intro-to-kubernetes/`: Kubernetes manifests, RBAC examples, and small HTML assets (`blue-web/`, `green-web/`).
- `Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server/`: Node/Falcor demo server and nested demo packages.
- `README.md`: top-level project note.
- IDE metadata (`.idea/`, `*.iml`) is present; avoid broad formatting-only edits to these files.

## Build, Test, and Development Commands
Run commands from the directory that contains the target `package.json`.

- `cd Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server && npm install`: install server dependencies.
- `npm start` (inside `.../falcor-express-demo`): run the express demo with `nodemon` + watcher.
- `npm start` (inside `.../falcor-router-demo`): run the router demo (`node index.js`).
- `kubectl apply --dry-run=client -f Edx-Courses/LFS158x-intro-to-kubernetes/webserver.yaml`: validate Kubernetes YAML without applying.

## Coding Style & Naming Conventions
- Use 2 spaces in YAML and JSON; preserve existing indentation in JS files.
- Keep file names descriptive and lowercase with hyphens for manifests (for example, `virtual-host-ingress.yaml`).
- Prefer small, focused edits in course folders; do not refactor vendored/demo dependencies under `node_modules/`.

## Testing Guidelines
There is no enforced automated test suite at repo root. Existing Node packages mostly use placeholder `npm test` scripts.

- For Kubernetes examples, validate with `kubectl apply --dry-run=client -f <file>`.
- For GraphQL/Falcor examples, verify by starting the relevant demo and checking startup logs and local endpoint behavior.

## Commit & Pull Request Guidelines
Recent history uses short imperative messages (for example, `Cleanup and reorganization.`). Keep this style, but make scope explicit.

- Commit format: `<area>: <imperative summary>` (example: `k8s: add canary service manifest`).
- PRs should include: purpose, changed paths, how you validated (`kubectl dry-run`, `npm start`), and screenshots/log snippets when UI or runtime behavior changes.
