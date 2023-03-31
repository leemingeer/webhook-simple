
## webhook simple 
```
#!/usr/bin/env bash

cd hacks && bash gen-certs.sh && cd -
kubectl apply -f deploy/
docker build -t leemingeer/webhook:v1 .
docker push leemingeer/webhook:v1
```