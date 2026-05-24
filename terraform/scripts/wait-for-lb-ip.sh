#!/bin/sh
# Wait for the envoy data plane LoadBalancer Service to receive an EXTERNAL-IP
# from cloud-provider-kind, then emit `{"ip":"..."}` on stdout.
#
# Invoked by the hashicorp/external Terraform provider:
#   data "external" "envoy_lb_ip" {
#     program = ["wait-for-lb-ip.sh", CACHE_FILE, CONTEXT, NAMESPACE, SELECTOR, TIMEOUT_SECONDS]
#   }
#
# Caches the discovered IP so subsequent `terraform plan`/`refresh` runs do not
# re-poll the cluster. Delete the cache file to force re-discovery.
set -eu

# Drain stdin (external provider always sends a JSON query, possibly empty).
cat >/dev/null

cache_file="${1:?cache file path required}"
context="${2:?kube context required}"
namespace="${3:?namespace required}"
selector="${4:?label selector required}"
timeout="${5:-600}"

emit() {
  printf '{"ip":"%s"}\n' "$1"
}

if [ -f "$cache_file" ]; then
  cached=$(cat "$cache_file")
  if [ -n "$cached" ]; then
    emit "$cached"
    exit 0
  fi
fi

end=$(( $(date +%s) + timeout ))
while [ "$(date +%s)" -lt "$end" ]; do
  ip=$(
    kubectl --context "$context" -n "$namespace" get svc \
      -l "$selector" \
      -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true
  )
  if [ -n "$ip" ]; then
    mkdir -p "$(dirname "$cache_file")"
    printf '%s' "$ip" >"$cache_file"
    emit "$ip"
    exit 0
  fi
  sleep 5
done

echo "wait-for-lb-ip: timed out after ${timeout}s waiting for $selector in $namespace" >&2
exit 1
