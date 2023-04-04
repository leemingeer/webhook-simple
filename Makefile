
.PHONY: webhook
webhook:
	bash hacks/gen-certs.sh

.PHONY: build
build:
	go build -o webhook cmd/main.go

.PHONY: image
image:
	docker build -t leemingeer/webhook:v1 .

.PHONY: deploy
deploy:
	kubectl delete -f deploy/
	kubectl apply -f deploy/

.PHONY: test
test:
	kubectl delete -f example/nginx.yaml
	kubectl apply -f example/nginx.yaml