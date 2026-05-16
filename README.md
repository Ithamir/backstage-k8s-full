# Deploying Backstage on Kubernetes (KinD + Terraform + Gateway API)

A local Kubernetes development environment for Backstage, provisioned by Terraform with Envoy Gateway for ingress.

**Official Documentation:**

- [Backstage Docker Deployment](https://backstage.io/docs/deployment/docker/)
- [Backstage Kubernetes Deployment](https://backstage.io/docs/deployment/k8s)
- [Backstage Authentication](https://backstage.io/docs/auth/)

## Prerequisites

Install the following tools:

- [Docker](https://docs.docker.com/get-docker/)
- [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.5)
- [Helm](https://helm.sh/docs/intro/install/) (>= 3.x)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Node.js 20 or 22 (for building Backstage from source)

### Node.js Version

Backstage requires Node.js 20 or 22. Using an older or incompatible version will cause native module compilation failures, particularly with `isolated-vm` which depends on V8 APIs that change between Node versions.

```bash
# Install nvm if not already installed
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc

# Install and use Node 22 (recommended - matches the Dockerfile runtime)
nvm install 22
nvm use 22
```

### Build Dependencies

Install build tools required for compiling native Node.js modules:

```bash
sudo apt-get update
sudo apt-get install -y python3 g++ build-essential
```

## Step 1: Create the Backstage App

```bash
npx @backstage/create-app@latest
```

This scaffolds a complete Backstage application in a `backstage/` folder with all necessary files.

## Step 2: Configure Repository Files

Three files in your generated `backstage/` directory need to be replaced or added. The reference versions live in this repo at the matching paths — overwrite or create them in your `backstage/` directory before building:

| File | Purpose |
|------|---------|
| `backstage/Dockerfile` | Multi-stage build that compiles everything inside Docker |
| `backstage/.dockerignore` | Must NOT exclude source files (unlike the host build version) |
| `backstage/app-config.production.yaml` | Production overrides with database connection, guest auth, and Gateway URL |

Key configuration notes:

`backstage/.dockerignore` must NOT exclude `packages/*/src`. The default from `create-app` excludes source files, which causes `yarn tsc` to fail with "No inputs were found".

`backstage/app-config.production.yaml` must include `dangerouslyAllowOutsideDevelopment: true` under the guest auth provider. Without this, you will get 401 Unauthorized errors because guest auth is disabled by default in containerized environments.

## Step 3: Provision the Cluster

Terraform brings up a KinD cluster, a local Docker registry, and the Envoy Gateway controller:

```bash
cd terraform
terraform init
terraform apply
```

This creates:
- A 2-node KinD cluster (1 control-plane + 1 worker) with port 8080 mapped to the Envoy data plane
- A local Docker registry at `localhost:5001`
- Gateway API CRDs + Envoy Gateway controller
- A custom `GatewayClass` (`eg-nodeport`) wired for NodePort exposure

Verify the cluster is ready:

```bash
kubectl get nodes
# Should show 2 nodes (control-plane + worker) in Ready state
```

## Step 4: Build and Push the Image

Build the Backstage image and push it to the local registry:

```bash
docker build -t localhost:5001/backstage:1.0.0 backstage/
docker push localhost:5001/backstage:1.0.0
```

The image is now available to the cluster via the registry — no manual image loading required.

## Step 5: Deploy with Helm

Install the edge-gateway chart (shared Gateway resource) and then the backstage chart:

```bash
# Install the edge-gateway (creates the gateway namespace)
helm upgrade --install edge-gateway charts/edge-gateway \
  --namespace gateway --create-namespace --wait \
  --kube-context kind-backstage \
  -f deploy/kind/edge-gateway.yaml

# Pre-create the backstage namespace (idempotent)
kubectl create namespace backstage --dry-run=client -o yaml | kubectl apply -f - --context kind-backstage

# Install backstage
helm upgrade --install backstage charts/backstage \
  --namespace backstage --wait --timeout 5m \
  --kube-context kind-backstage \
  -f deploy/kind/backstage.yaml
```

Or simply run the full smoke test which performs all of the above:

```bash
make smoke
```

## Step 6: Access Backstage

Open <http://backstage.localtest.me:8080> in your browser. No port-forwarding required.

`localtest.me` is a real DNS domain that resolves to 127.0.0.1. Traffic flows through KinD's port mappings into the Envoy Gateway, which routes based on the hostname to the Backstage service.

You should see the Backstage UI and be able to log in as a guest.

## Updating Backstage

When you make changes and need to redeploy:

```bash
# Build with a new tag
docker build -t localhost:5001/backstage:1.0.1 backstage/
docker push localhost:5001/backstage:1.0.1

# Upgrade the helm release with the new image tag
helm upgrade backstage charts/backstage \
  --namespace backstage --wait --timeout 5m \
  --kube-context kind-backstage \
  -f deploy/kind/backstage.yaml \
  --set image.tag=1.0.1
```

## Useful Commands

```bash
# View pod logs
kubectl logs -n backstage -l app.kubernetes.io/name=backstage

# View pod logs with timestamps
kubectl logs -n backstage deploy/backstage --timestamps

# Restart deployment
kubectl rollout restart deployment backstage -n backstage

# Check Gateway status
kubectl get gateway -n gateway
kubectl get httproute -n backstage

# View Envoy Gateway controller logs
kubectl logs -n envoy-gateway-system deploy/envoy-gateway

# List images in local registry
curl -s http://localhost:5001/v2/_catalog

# View all resources in the namespace
kubectl get all -n backstage

# Uninstall charts
helm uninstall backstage -n backstage
helm uninstall edge-gateway -n gateway

# Tear down the cluster
cd terraform && terraform destroy
```

## Smoke Test

Run the full end-to-end verification (assumes image is already pushed to the local registry):

```bash
make smoke
```

Run Terraform validation only:

```bash
make tf-check
```

Run Helm chart linting only:

```bash
make charts-lint
```

## Next Steps

1. **Configure a production auth provider** — Replace guest auth with GitHub, Google, Okta, or another provider. See the [Authentication documentation](https://backstage.io/docs/auth/).

2. **Add catalog entities** — Populate the software catalog with your services, APIs, and documentation.

3. **Configure the Kubernetes plugin** — Enable viewing Kubernetes resources from within Backstage.

4. **Set up TechDocs** — Enable documentation generation and viewing.

5. **Deploy to a production cluster** — Move beyond KinD to EKS, GKE, or another managed Kubernetes service.

6. **Add HTTPS** — Configure cert-manager or mkcert for TLS termination at the Gateway.

## Architecture Decision

See [ADR-0001](docs/adr/0001-kind-terraform-envoy-gateway.md) for the full rationale behind the KinD + Terraform + Envoy Gateway architecture.
