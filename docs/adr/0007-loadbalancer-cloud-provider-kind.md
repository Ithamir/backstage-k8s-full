# ADR-0007: LoadBalancer via cloud-provider-kind

## Status

Accepted

## Context

The original KinD exposure path used `Service.type=NodePort` plus KinD `extraPortMappings` from host port 8080 to node port 30080. That worked, but it made the local Envoy data plane Service dev-only, leaked `:8080` into every URL, and made future exposed services depend on Terraform/KinD port mapping changes.

The current local development goal is a Service shape that looks like a production cluster: `Service.type=LoadBalancer` with normal HTTP URLs such as `http://backstage.localtest.me`.

## Decision

Use `cloud-provider-kind` in Linux native mode to reconcile the Envoy data plane Service as `type: LoadBalancer`. Terraform manages the daemon as a docker container using `kreuzwerker/docker`, pinned to `registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.10.0`, with host networking and `/var/run/docker.sock` mounted.

The `--enable-lb-port-mapping` flag is deliberately not used. The upstream cloud-provider-kind README documents that flag under "Enabling Load Balancer Port Mapping" and discusses it again under "Mac, Windows and WSL2 support"; it is a fallback for environments where the Docker bridge is not directly reachable from the host and uses Docker port mapping rather than a stable host URL strategy. This repo's local stack is Linux-only for this path.

The Envoy data plane Service does **not** request a static IP via `spec.loadBalancerIP`. That field was deprecated in Kubernetes 1.24 and cloud-provider-kind does not honor it — an earlier iteration of this stack pinned `loadBalancerIP: 172.18.0.250`, observed `status.loadBalancer.ingress[0].ip: 172.18.0.4` in practice, and the host nginx forwarder returned `502 Bad Gateway` because it targeted the requested-but-unhonored address. Instead, Terraform discovers the actual EXTERNAL-IP at apply time via a `data "external"` source backed by `terraform/scripts/wait-for-lb-ip.sh`. The script polls the data plane Service until `status.loadBalancer.ingress[0].ip` is populated by cloud-provider-kind, caches the result in `terraform/.generated/envoy-lb-ip` so subsequent `terraform plan`/`refresh` runs do not re-poll, and emits `{"ip":"..."}` for Terraform to consume.

Because `*.localtest.me` resolves to loopback rather than the KinD bridge address, Terraform also manages a second docker container running `nginx:1.27-alpine`. The nginx container uses host networking, listens on `127.0.0.1:80` only (so the host's port 80 on every non-loopback interface stays free for other processes), preserves the `Host` header, and forwards all HTTP traffic to the dynamically discovered LoadBalancer IP on port 80. The nginx container is configured to be replaced whenever the rendered config changes (via `replace_triggered_by` on the `terraform_data` resource that writes the config), so a new EXTERNAL-IP causes an automatic nginx restart. nginx is only the explicit cloud-LB-to-host-port bridge; Envoy Gateway remains the in-cluster routing layer.

## Consequences

Terraform now has six providers: `kreuzwerker/docker` and `hashicorp/external` are the additions for this exposure scheme, alongside `tehcyx/kind`, `hashicorp/helm`, `hashicorp/kubernetes`, and `gavinbunney/kubectl`. The two new local docker containers are `cloud-provider-kind` and the nginx forwarder. `terraform apply` starts the local LoadBalancer machinery with the cluster, and `terraform destroy` removes it with the rest of the stack.

The docker socket mount is a deliberate dev-only concession. A process with access to `/var/run/docker.sock` can control the host Docker daemon, so this is not a production trust boundary.

The local platform no longer uses KinD `extraPortMappings` or a hardcoded Envoy NodePort. URLs drop the `:8080` suffix: `http://backstage.localtest.me` and `http://argocd.localtest.me`.

Because nginx binds `127.0.0.1:80` rather than `0.0.0.0:80`, host port 80 on other interfaces (eth0, wifi, additional docker bridges) is still available. Any other process that wants `127.0.0.1:80` (most local web servers default to that) will still conflict; in that case stop the conflicting process or stop this stack.

The Envoy data plane Service's EXTERNAL-IP is not stable across `terraform destroy` / re-apply cycles or across changes in the order cloud-provider-kind allocates IPs on the docker bridge. The nginx container picks up whatever IP is assigned, so URLs continue to work. To force re-discovery during a single cluster's lifetime, delete `terraform/.generated/envoy-lb-ip` and re-apply.

Mac, Windows, and WSL2 are explicitly not supported by this exposure scheme. Those platforms need a different bridge because the KinD Docker bridge is not directly routable from the host in the same way.

## References

- [cloud-provider-kind README](https://github.com/kubernetes-sigs/cloud-provider-kind), especially the "Enabling Load Balancer Port Mapping" and "Mac, Windows and WSL2 support" sections.
- [KinD LoadBalancer guide](https://kind.sigs.k8s.io/docs/user/loadbalancer/).
- [Kubernetes 1.24 release notes — `Service.spec.loadBalancerIP` deprecation](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.24.md).
