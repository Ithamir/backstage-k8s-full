.PHONY: smoke tf-check image charts-lint charts-test docs-lint docs-serve

KUBE_CONTEXT := kind-backstage
GATEWAY_NS := gateway
BACKSTAGE_NS := backstage
BACKSTAGE_IMAGE := localhost:5001/backstage:1.0.0
SITES := $(shell find . -name mkdocs.yaml -not -path '*/node_modules/*')

image:
	docker build -t $(BACKSTAGE_IMAGE) backstage/
	docker push $(BACKSTAGE_IMAGE)

tf-check:
	terraform -chdir=terraform fmt -check -recursive
	terraform -chdir=terraform validate

charts-lint:
	helm lint charts/edge-gateway -f deploy/kind/edge-gateway.yaml
	helm lint charts/backstage -f deploy/kind/backstage.yaml

charts-test:
	./tests/charts/test-backstage-image.sh
	./tests/charts/test-backstage-secrets.sh
	./tests/charts/test-backstage-configmap.sh
	./tests/charts/test-backstage-catalog-config.sh
	./tests/charts/test-backstage-mkdocs-image-toolchain.sh
	./tests/charts/test-backstage-techdocs-config.sh

docs-lint:
	@for site in $(SITES); do \
		dir=$$(dirname "$$site"); \
		echo "Building docs site $$dir"; \
		docker run --rm -v "$(PWD):/workspace" -w "/workspace/$$dir" $(BACKSTAGE_IMAGE) mkdocs build --strict; \
	done

docs-serve:
	@test -n "$(ENTITY)" || (echo "ERROR: ENTITY=<path> is required, for example ENTITY=."; exit 1)
	docker run --rm -it -p 8000:8000 -v "$(PWD):/workspace" -w "/workspace/$(ENTITY)" $(BACKSTAGE_IMAGE) mkdocs serve --dev-addr=0.0.0.0:8000

smoke: tf-check charts-lint charts-test
	terraform -chdir=terraform apply -auto-approve
	helm upgrade --install edge-gateway charts/edge-gateway \
		--namespace $(GATEWAY_NS) --create-namespace --wait \
		--kube-context $(KUBE_CONTEXT) \
		-f deploy/kind/edge-gateway.yaml
	kubectl create namespace $(BACKSTAGE_NS) --dry-run=client -o yaml | kubectl apply -f - --context $(KUBE_CONTEXT)
	kubectl label namespace $(BACKSTAGE_NS) gateway-routes=enabled --overwrite --context $(KUBE_CONTEXT)
	@echo "Checking for backstage-github-token secret..."
	@kubectl get secret backstage-github-token -n $(BACKSTAGE_NS) --context $(KUBE_CONTEXT) >/dev/null 2>&1 || \
		(echo "ERROR: Secret backstage-github-token not found in namespace $(BACKSTAGE_NS)." && \
		 echo "Create it with:" && \
		 echo '  kubectl create secret generic backstage-github-token --from-literal=GITHUB_TOKEN="$$GITHUB_TOKEN" -n $(BACKSTAGE_NS) --context $(KUBE_CONTEXT)' && \
		 exit 1)
	helm upgrade --install backstage charts/backstage \
		--namespace $(BACKSTAGE_NS) --wait --timeout 5m \
		--kube-context $(KUBE_CONTEXT) \
		-f deploy/kind/backstage.yaml
	kubectl wait --for=condition=Available deployment/backstage \
		-n $(BACKSTAGE_NS) --timeout=300s --context $(KUBE_CONTEXT)
	@echo "Verifying Backstage is reachable..."
	curl -fsS http://backstage.localtest.me:8080 | grep -q '<title>'
	@echo "Verifying catalog is non-empty..."
	@curl -fsS http://backstage.localtest.me:8080/api/catalog/entities | grep -q '"kind"' || \
		(echo "WARN: Catalog appears empty — GitHub discovery may not have completed yet." && exit 1)
	@echo "Smoke test passed."
