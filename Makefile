.PHONY: smoke tf-check image charts-lint charts-test

KUBE_CONTEXT := kind-backstage
GATEWAY_NS := gateway
BACKSTAGE_NS := backstage

image:
	docker build -t localhost:5001/backstage:1.0.0 backstage/
	docker push localhost:5001/backstage:1.0.0

tf-check:
	terraform -chdir=terraform fmt -check -recursive
	terraform -chdir=terraform validate

charts-lint:
	helm lint charts/edge-gateway -f deploy/kind/edge-gateway.yaml
	helm lint charts/backstage -f deploy/kind/backstage.yaml

charts-test:
	./tests/charts/test-backstage-image.sh
	./tests/charts/test-backstage-secrets.sh

smoke: tf-check charts-lint charts-test
	terraform -chdir=terraform apply -auto-approve
	helm upgrade --install edge-gateway charts/edge-gateway \
		--namespace $(GATEWAY_NS) --create-namespace --wait \
		--kube-context $(KUBE_CONTEXT) \
		-f deploy/kind/edge-gateway.yaml
	kubectl create namespace $(BACKSTAGE_NS) --dry-run=client -o yaml | kubectl apply -f - --context $(KUBE_CONTEXT)
	helm upgrade --install backstage charts/backstage \
		--namespace $(BACKSTAGE_NS) --wait --timeout 5m \
		--kube-context $(KUBE_CONTEXT) \
		-f deploy/kind/backstage.yaml
	kubectl wait --for=condition=Available deployment/backstage \
		-n $(BACKSTAGE_NS) --timeout=300s --context $(KUBE_CONTEXT)
	@echo "Verifying Backstage is reachable..."
	curl -fsS http://backstage.localtest.me:8080 | grep -q '<title>'
	@echo "Smoke test passed."
