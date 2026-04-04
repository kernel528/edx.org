#!/usr/bin/env bash
set -euo pipefail

K8S_DIR="${K8S_DIR:-Edx-Courses/LFS158x-intro-to-kubernetes}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-180s}"
INGRESS_MODE="${INGRESS_MODE:-auto}"
PF_WEB_PORT="${PF_WEB_PORT:-18080}"
PF_CANARY_PORT="${PF_CANARY_PORT:-18083}"

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

preflight_cluster_access() {
  local raw_version

  if ! raw_version="$(kubectl get --raw /version 2>/dev/null)"; then
    printf "Unable to reach Kubernetes API server with current kubeconfig/context.\n" >&2
    printf "Check: kubectl config current-context\n" >&2
    printf "Then test: kubectl cluster-info\n" >&2
    exit 1
  fi

  if [[ "${raw_version}" != \{* ]]; then
    printf "Connected endpoint did not return Kubernetes JSON for /version.\n" >&2
    printf "Got non-JSON response (often HTML/login page/proxy).\n" >&2
    printf "Check VPN/proxy and kubeconfig server URL:\n" >&2
    printf "  kubectl config view --minify\n" >&2
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

wait_rollout() {
  local deploy_name="$1"
  kubectl rollout status "deployment/${deploy_name}" --timeout="${WAIT_TIMEOUT}"
}

ingress_class_exists() {
  local class_name="$1"
  kubectl get ingressclass "${class_name}" >/dev/null 2>&1
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

preflight_cluster_access

log "Cluster sanity"
if kubectl version --short >/dev/null 2>&1; then
  kubectl version --short
else
  kubectl version --client
  printf "Note: kubectl does not support --short in this version.\n"
fi
kubectl get nodes -o wide

log "1) Baseline NGINX deployment and service"
kubectl apply -f "$K8S_DIR/webserver.yaml"
kubectl apply -f "$K8S_DIR/webserver-svc.yaml"
wait_rollout webserver
kubectl get deploy webserver
kubectl get pods -l app=nginx -o wide
kubectl get svc web-service

log "2) Single pod and liveness probe demo"
kubectl delete pod nginx-pod liveness-exec --ignore-not-found
kubectl apply -f "$K8S_DIR/nginx.yaml"
kubectl apply -f "$K8S_DIR/probe.yml"
kubectl wait --for=condition=Ready pod/nginx-pod --timeout="${WAIT_TIMEOUT}"
kubectl wait --for=condition=Ready pod/liveness-exec --timeout="${WAIT_TIMEOUT}"
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
wait_rollout blue-web
wait_rollout green-web
kubectl get deploy blue-web green-web
kubectl get svc blue-web green-web

log "5) Shared-volume blue/green deployments and canary service"
kubectl apply -f "$K8S_DIR/app-blue-shared-vol.yaml"
kubectl apply -f "$K8S_DIR/app-green-shared-vol.yaml"
kubectl apply -f "$K8S_DIR/canary-svc.yaml"
wait_rollout blue-app
wait_rollout green-app
kubectl get pods -l type=canary -o wide
kubectl get svc canary

log "6) Host-based ingress"
if [[ "${INGRESS_MODE}" == "false" ]]; then
  printf "Skipping ingress apply because INGRESS_MODE=false.\n"
elif [[ "${INGRESS_MODE}" == "true" ]]; then
  kubectl apply -f "$K8S_DIR/virtual-host-ingress.yaml"
  kubectl get ingress virtual-host-ingress
else
  if ingress_class_exists nginx; then
    kubectl apply -f "$K8S_DIR/virtual-host-ingress.yaml"
    kubectl get ingress virtual-host-ingress
  else
    printf "Skipping ingress apply: no ingressClass named 'nginx'.\n"
    printf "Set INGRESS_MODE=true to force apply, or install ingress-nginx first.\n"
  fi
fi

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
  kubectl port-forward svc/web-service ${PF_WEB_PORT}:80
  kubectl port-forward svc/canary ${PF_CANARY_PORT}:80

Optional CSR approval:
  kubectl certificate approve joe-csr

Environment toggles:
  WAIT_TIMEOUT=180s   # rollout/wait timeout for pods/deployments
  INGRESS_MODE=auto   # auto|true|false
  PF_WEB_PORT=18080   # local port for web-service port-forward
  PF_CANARY_PORT=18083 # local port for canary port-forward

EOF
