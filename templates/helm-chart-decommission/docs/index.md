# Helm Chart Decommission Template

The `helm-chart-decommission` Template opens a pull request that removes a scaffolded workload chart from this repository. It is intended for Components originally created by the `helm-chart` Template.

The Template is deliberately conservative. It validates the selected catalog entity, checks for catalog relationships that would make removal unsafe, calculates the exact repository files to delete, and then creates a GitHub pull request for review.

## What It Removes

The pull request deletes the selected chart directory:

```text
charts/<component-name>/
```

For charts scaffolded by the `helm-chart` Template, that directory includes the Helm chart, workload catalog entity, `mkdocs.yaml`, and the chart's `docs/` folder. Removing the directory therefore removes both the deployable chart source and the co-located TechDocs source for that Component.

## What It Does Not Remove

The Template does not uninstall anything from Kubernetes. It does not run `helm uninstall`, delete Deployments or Services, remove namespaces, or clean up live `HTTPRoute` resources directly.

After the pull request merges, the requester still needs to remove any running release manually until a deployment controller such as Argo CD owns that lifecycle:

```bash
helm uninstall <component-name> -n <namespace>
```

The Template also does not remove external DNS records, secrets, databases, queues, object storage, or downstream dependencies. Those resources must be handled by the owning team before or alongside the repository cleanup.

## Pull Request Output

The generated pull request targets `main` on a branch named `decommission/helm-chart/<component-name>`. Its description records the Component name, removed path, file count, requesting user, and a warning that the running Helm release is not uninstalled automatically.
