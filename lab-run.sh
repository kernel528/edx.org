#!/usr/bin/env bash
set -euo pipefail

K8S_DIR="${K8S_DIR:-Edx-Courses/LFS158x-intro-to-kubernetes}"

log() {
  printf "\n==> %s\n" "$1"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf "Missing required command: %s\n" "$1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    printf "Required file not found: %s\n" "$1" >&2
    exit 1
  fi
}

apply_service() {
  local name="$1"
  local selector="$2"

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${name}
spec:
  type: ClusterIP
  selector:
    app: ${selector}
  ports:
  - name: http
    port: 80
    targetPort: 80
EOF
}

require_cmd kubectl
require_file "$K8S_DIR/webserver.yaml"
require_file "$K8S_DIR/webserver-svc.yaml"
require_file "$K8S_DIR/nginx.yaml"
require_file "$K8S_DIR/probe.yml"
require_file "$K8S_DIR/customer1-configmap.yaml"
require_file "$K8S_DIR/mypass.yaml"
require_file "$K8S_DIR/blue-web/index.html"
require_file "$K8S_DIR/green-web/index.html"
require_file "$K8S_DIR/blue-web/web-blue-with-cm.yaml"
require_file "$K8S_DIR/green-web/web-green-with-cm.yaml"
require_file "$K8S_DIR/app-blue-shared-vol.yaml"
require_file "$K8S_DIR/app-green-shared-vol.yaml"
require_file "$K8S_DIR/canary-svc.yaml"
require_file "$K8S_DIR/virtual-host-ingress.yaml"
require_file "$K8S_DIR/rbac/role.yaml"
require_file "$K8S_DIR/rbac/rolebinding.yaml"
require_file "$K8S_DIR/rbac/signing-request.yaml"

log "Cluster sanity"
kubectl version --short
kubectl get nodes -o wide

log "1) Baseline NGINX deployment and service"
kubectl apply -f "$K8S_DIR/webserver.yaml"
kubectl apply -f "$K8S_DIR/webserver-svc.yaml"
kubectl get deploy webserver
kubectl get pods -l app=nginx -o wide
kubectl get svc web-service

log "2) Single pod and liveness probe demo"
kubectl apply -f "$K8S_DIR/nginx.yaml"
kubectl apply -f "$K8S_DIR/probe.yml"
kubectl get pod nginx-pod liveness-exec

log "3) ConfigMap and Secret"
kubectl apply -f "$K8S_DIR/customer1-configmap.yaml"
kubectl apply -f "$K8S_DIR/mypass.yaml"
kubectl get configmap customer1
kubectl get secret my-password

log "4) Blue/Green configmap-backed web deployments"
kubectl create configmap blue-web-cm --from-file="$K8S_DIR/blue-web/index.html" --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap green-web-cm --from-file="$K8S_DIR/green-web/index.html" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$K8S_DIR/blue-web/web-blue-with-cm.yaml"
kubectl apply -f "$K8S_DIR/green-web/web-green-with-cm.yaml"
apply_service blue-web blue-web
apply_service green-web green-web
kubectl get deploy blue-web green-web
kubectl get svc blue-web green-web

log "5) Shared-volume blue/green deployments and canary service"
kubectl apply -f "$K8S_DIR/app-blue-shared-vol.yaml"
kubectl apply -f "$K8S_DIR/app-green-shared-vol.yaml"
kubectl apply -f "$K8S_DIR/canary-svc.yaml"
kubectl get pods -l type=canary -o wide
kubectl get svc canary

log "6) Host-based ingress"
kubectl apply -f "$K8S_DIR/virtual-host-ingress.yaml"
kubectl get ingress virtual-host-ingress

log "7) RBAC and CSR workflow"
kubectl create namespace sanders-edx --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$K8S_DIR/rbac/role.yaml"
kubectl apply -f "$K8S_DIR/rbac/rolebinding.yaml"
kubectl apply -f "$K8S_DIR/rbac/signing-request.yaml"
kubectl get role -n sanders-edx
kubectl get rolebinding -n sanders-edx
kubectl get csr joe-csr

log "8) Full status snapshot"
kubectl get all
kubectl get configmap,secret
kubectl get ingress
kubectl get role,rolebinding -n sanders-edx
kubectl get csr

cat <<'EOF'

Lab apply complete.

Optional interactive checks:
  kubectl get pod liveness-exec -w
  kubectl describe ingress virtual-host-ingress
  kubectl describe svc canary
  kubectl port-forward svc/web-service 8080:80

Optional CSR approval:
  kubectl certificate approve joe-csr

EOF
