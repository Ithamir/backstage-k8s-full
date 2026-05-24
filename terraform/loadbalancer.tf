resource "docker_image" "cloud_provider_kind" {
  name = "registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.10.0"
}

resource "docker_container" "cloud_provider_kind" {
  name         = "${var.cluster_name}-cloud-provider-kind"
  image        = docker_image.cloud_provider_kind.image_id
  restart      = "unless-stopped"
  network_mode = "host"

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = false
  }

  depends_on = [kind_cluster.this]
}

data "external" "envoy_lb_ip" {
  program = [
    "${path.module}/scripts/wait-for-lb-ip.sh",
    local.envoy_lb_ip_cache,
    "kind-${var.cluster_name}",
    "envoy-gateway-system",
    "gateway.envoyproxy.io/owning-gateway-namespace=gateway,gateway.envoyproxy.io/owning-gateway-name=edge-gateway",
    "600",
  ]

  depends_on = [
    kubectl_manifest.root_app,
    docker_container.cloud_provider_kind,
  ]
}

resource "docker_image" "nginx_lb_proxy" {
  name = "nginx:1.27-alpine"
}

resource "terraform_data" "nginx_lb_proxy_config" {
  input            = local.nginx_lb_proxy_config_raw
  triggers_replace = local.nginx_lb_proxy_config_raw

  provisioner "local-exec" {
    command     = "mkdir -p '${local.generated_dir}' && printf '%s' \"$NGINX_LB_PROXY_CONFIG\" > '${local.nginx_lb_proxy_config}'"
    interpreter = ["/bin/sh", "-c"]

    environment = {
      NGINX_LB_PROXY_CONFIG = self.input
    }
  }
}

resource "docker_container" "nginx_lb_proxy" {
  name         = "${var.cluster_name}-nginx-lb-proxy"
  image        = docker_image.nginx_lb_proxy.image_id
  restart      = "unless-stopped"
  network_mode = "host"

  volumes {
    host_path      = local.nginx_lb_proxy_config
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }

  depends_on = [
    docker_container.cloud_provider_kind,
    terraform_data.nginx_lb_proxy_config,
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.nginx_lb_proxy_config]
  }
}
