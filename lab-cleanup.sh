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

delete_manifest_if_exists() {
  local file_path="$1"
  if [[ -f "$file_path" ]]; then
    kubectl delete -f "$file_path" --ignore-not-found
  else
    printf "Skipping missing manifest: %s\n" "$file_path"
  fi
}

require_cmd kubectl

log "Deleting ingress and canary resources"
delete_manifest_if_exists "$K8S_DIR/virtual-host-ingress.yaml"
delete_manifest_if_exists "$K8S_DIR/canary-svc.yaml"

log "Deleting shared-volume and blue/green deployments"
delete_manifest_if_exists "$K8S_DIR/app-blue-shared-vol.yaml"
delete_manifest_if_exists "$K8S_DIR/app-green-shared-vol.yaml"
delete_manifest_if_exists "$K8S_DIR/blue-web/web-blue-with-cm.yaml"
delete_manifest_if_exists "$K8S_DIR/green-web/web-green-with-cm.yaml"

log "Deleting baseline web resources and probe demos"
delete_manifest_if_exists "$K8S_DIR/webserver-svc.yaml"
delete_manifest_if_exists "$K8S_DIR/webserver.yaml"
delete_manifest_if_exists "$K8S_DIR/nginx.yaml"
delete_manifest_if_exists "$K8S_DIR/probe.yml"

log "Deleting ConfigMap and Secret manifests"
delete_manifest_if_exists "$K8S_DIR/customer1-configmap.yaml"
delete_manifest_if_exists "$K8S_DIR/mypass.yaml"

log "Deleting additional runtime-created services/configmaps"
kubectl delete svc blue-web green-web web-service --ignore-not-found
kubectl delete configmap blue-web-cm green-web-cm --ignore-not-found

log "Deleting RBAC and CSR resources"
delete_manifest_if_exists "$K8S_DIR/rbac/rolebinding.yaml"
delete_manifest_if_exists "$K8S_DIR/rbac/role.yaml"
delete_manifest_if_exists "$K8S_DIR/rbac/signing-request.yaml"
kubectl delete csr joe-csr --ignore-not-found

log "Deleting lab namespace"
kubectl delete namespace sanders-edx --ignore-not-found

log "Post-cleanup snapshot"
kubectl get all --all-namespaces

cat <<'EOF'

Lab cleanup complete.

Tip:
  If resources still appear, they may be in Terminating state.
  Re-run this script after a short wait.

EOF
