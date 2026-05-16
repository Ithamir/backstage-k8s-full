resource "helm_release" "gateway_crds" {
  name             = "gateway-crds"
  chart            = "oci://docker.io/envoyproxy/gateway-crds-helm"
  version          = "v1.8.0"
  create_namespace = true
  namespace        = "envoy-gateway-system"

  depends_on = [kind_cluster.this]
}

resource "helm_release" "gateway" {
  name             = "eg"
  chart            = "oci://docker.io/envoyproxy/gateway-helm"
  version          = "v1.8.0"
  create_namespace = true
  namespace        = "envoy-gateway-system"

  set {
    name  = "crds.enabled"
    value = "false"
  }

  depends_on = [helm_release.gateway_crds]
}

resource "kubectl_manifest" "envoy_proxy" {
  yaml_body = <<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyProxy
    metadata:
      name: custom-proxy-config
      namespace: envoy-gateway-system
    spec:
      provider:
        type: Kubernetes
        kubernetes:
          envoyService:
            type: NodePort
            patch:
              type: StrategicMerge
              value:
                spec:
                  ports:
                  - port: 80
                    nodePort: 30080
                    protocol: TCP
  YAML

  depends_on = [helm_release.gateway]
}

resource "kubectl_manifest" "gateway_class" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: GatewayClass
    metadata:
      name: eg-nodeport
    spec:
      controllerName: gateway.envoyproxy.io/gatewayclass-controller
      parametersRef:
        group: gateway.envoyproxy.io
        kind: EnvoyProxy
        name: custom-proxy-config
        namespace: envoy-gateway-system
  YAML

  depends_on = [kubectl_manifest.envoy_proxy]
}
