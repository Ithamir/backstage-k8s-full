.PHONY: smoke tf-check image

image:
	docker build -t localhost:5001/backstage:1.0.0 backstage/
	docker push localhost:5001/backstage:1.0.0

tf-check:
	terraform -chdir=terraform fmt -check -recursive
	terraform -chdir=terraform validate

smoke:
	terraform -chdir=terraform apply -auto-approve
	kubectl apply -f kubernetes/
	kubectl wait --for=condition=Ready pod -l app=backstage -n backstage --timeout=300s
	kubectl wait --for=condition=Programmed gateway/backstage-gateway -n gateway --timeout=60s
	@echo "Verifying Backstage is reachable..."
	curl -fsS http://backstage.localtest.me:8080 | grep -q '<title>'
	@echo "Smoke test passed."
