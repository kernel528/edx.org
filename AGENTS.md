# Repository Guidelines

## Project Overview

This repository stores EdX course artifacts - not a single deployable application. It contains examples from multiple EdX courses including Kubernetes (LFS158x), GraphQL (LFS141x), and React examples.

## Project Structure & Module Organization

```
edx.org/
├── Edx-Courses/
│   ├── LFS158x-intro-to-kubernetes/     # Kubernetes manifests and examples
│   │   ├── rbac/                        # RBAC examples
│   │   ├── blue-web/                    # Blue web app assets
│   │   └── green-web/                  # Green web app assets
│   ├── LFS141x-exploring-graphql/       # GraphQL/Falcor demos
│   │   └── factor-express-demo/
│   │       └── falcor-app-server/
│   │           ├── falcor-express-demo/ # Express + Falcor demo
│   │           └── falcor-router-demo/  # Router demo service
│   └── (other course materials)
├── README.md                             # Top-level project note
└── .gitignore
```

## Build, Test, and Development Commands

### Node.js Projects

All Node commands must run from the directory containing the target `package.json`.

**falcor-app-server (parent):**
```bash
cd Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server && npm install
```

**falcor-express-demo:**
```bash
cd Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server/falcor-express-demo && npm install
npm start  # Runs with nodemon + livereload watcher
```

**falcor-router-demo:**
```bash
cd Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server/falcor-router-demo && npm install
npm start  # Runs: node index.js 2>&1
```

### Kubernetes YAML Validation

```bash
kubectl apply --dry-run=client -f Edx-Courses/LFS158x-intro-to-kubernetes/webserver.yaml
kubectl apply --dry-run=client -f <any-manifest>.yaml  # Validate any K8s manifest
```

### Testing

**There is no enforced automated test suite.** Most Node packages use placeholder `npm test` scripts that echo an error.

For manual verification:
- **Kubernetes**: Use `kubectl apply --dry-run=client` to validate manifests
- **Node/Falcor**: Start the demo server and check startup logs/local endpoint behavior

## Code Style & Formatting

### YAML Files
- **Indentation**: 2 spaces (mandatory)
- **Naming**: lowercase with hyphens (e.g., `virtual-host-ingress.yaml`, `webserver-svc.yaml`)
- **Consistency**: Preserve existing indentation patterns

### JavaScript Files
- **Indentation**: 2 spaces (preserve existing file patterns)
- **Strings**: Single quotes preferred (`'string'`)
- **Semicolons**: Use semicolons
- **Var declarations**: Use `var` for course/demo code (legacy patterns)
- **Strict mode**: Include `'use strict';` at the top of new modules

### Import Patterns
```javascript
// CommonJS (Node style) - no ES6 imports
var express = require('express');
var bodyParser = require('body-parser');
var Router = require('falcor-router');
```

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Files | lowercase with hyphens | `rating-service.js`, `cache.js` |
| Variables | camelCase | `userId`, `titleIds` |
| Constants | UPPER_SNAKE (if needed) | `MAX_RETRIES` |
| Classes | PascalCase | `NetflixRouterBase` |
| Routes (Falcor) | lowercase with dots | `genrelist[{integers}].name` |

### Error Handling
```javascript
// Use Error objects with descriptive messages
throw new Error("not authorized");

// Handle errors in promises
.catch(function(err) {
    console.error(err);
    return;
});

// Return $error values in Falcor routes
results.push({
    path: ['titlesById', titleId, key],
    value: $error(ratingRecord.error)
});
```

### Promise Patterns
```javascript
// Use the promise library (not native Promises for this codebase)
var Promise = require('promise');

return someAsyncOperation()
    .then(function(result) {
        return processResult(result);
    })
    .catch(function(error) {
        console.error(error);
    });
```

### Kubernetes Manifest Conventions
```yaml
# Example structure
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webserver
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
```

## Linting

The `falcor-express-demo` package includes ESLint (`^1.7.1`) as a devDependency:
```bash
cd Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server/falcor-express-demo && npm run lint
```

No project-wide linting is configured. Do not add linting to course/demo files in `node_modules/`.

## File Organization Guidelines

1. **Prefer small, focused edits** in course folders
2. **Do not refactor vendored/demo dependencies** under `node_modules/`
3. **Keep file names descriptive and lowercase with hyphens** for manifests
4. **Avoid broad formatting-only edits** to IDE metadata (`.idea/`, `*.iml`)

## Commit & Pull Request Guidelines

### Commit Message Format
```
<area>: <imperative summary>

Examples:
- k8s: add canary service manifest
- graphql: update router demo endpoints
- rbac: add pod-reader role definition
```

### PR Description Should Include
- **Purpose**: What the changes accomplish
- **Changed paths**: List of modified files
- **Validation**: How you tested (`kubectl dry-run`, `npm start`, etc.)
- **Evidence**: Screenshots or log snippets for UI/runtime changes

### Recent Commit Style
Recent history uses short imperative messages (e.g., `Cleanup and reorganization.`). Keep this style with explicit scope.
