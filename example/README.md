
# 测试

```shell
# make test
# kubectl get deploy nginx-deployment -o yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    annotations:
        admission-webhook-example.ming.com/status: mutated  // 已添加annotation
        deployment.kubernetes.io/revision: "1"
    creationTimestamp: "2023-04-04T15:42:52Z"
    ...
```

# trouble shooting
- 检查app的port、containerPort与Service的TargetPort三者是否一致 
- 检查pod间网络互通 
  - piServer pod通过kube-dns cluster ip做域名解析 
  - apiServer pod访问webhook pod 
- caBundle是否可以验证webhook server