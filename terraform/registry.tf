resource "docker_image" "registry" {
  name = "registry:2"
}

resource "docker_container" "kind_registry" {
  name  = "kind-registry"
  image = docker_image.registry.image_id

  restart = "always"

  ports {
    internal = 5000
    external = 5001
  }

  networks_advanced {
    name = "kind"
  }

  depends_on = [kind_cluster.this]
}

resource "terraform_data" "registry_hosts_toml" {
  triggers_replace = [kind_cluster.this.id, docker_container.kind_registry.id]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      for node in ${var.cluster_name}-control-plane ${var.cluster_name}-worker; do
        docker exec "$node" mkdir -p /etc/containerd/certs.d/localhost:5001
        docker exec "$node" sh -c 'cat > /etc/containerd/certs.d/localhost:5001/hosts.toml <<EOF
[host."http://kind-registry:5000"]
  capabilities = ["pull", "resolve"]
EOF'
      done
    EOT
  }
}
