locals {
  root_application = yamldecode(file("${path.module}/bootstrap/root-app.yaml"))

  generated_dir             = abspath("${path.module}/.generated")
  envoy_lb_ip_cache         = "${local.generated_dir}/envoy-lb-ip"
  nginx_lb_proxy_config     = "${local.generated_dir}/nginx-lb-proxy.conf"
  envoy_lb_ip               = data.external.envoy_lb_ip.result.ip
  nginx_lb_proxy_config_raw = <<-EOT
    server {
      listen 127.0.0.1:80;
      location / {
        proxy_set_header Host $host;
        proxy_pass http://${local.envoy_lb_ip}:80;
      }
    }
  EOT
}
