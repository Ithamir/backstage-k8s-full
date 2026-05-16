resource "docker_network" "kind" {
  name = "kind"
}

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
    name = docker_network.kind.id
  }
}
