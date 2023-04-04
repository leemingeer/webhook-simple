
## webhook simple

### 简介
webhookServer本质是在httpServer基础上，增加Handler。当request来时，可以根据其中的path, 路由到对应的handler处理。

go内置http包提供了NewServeMux作为http.Server的handler实现。并且其暴露`Handle`和`HandleFunc`两种方式，将自定义handler添加到请求路由中

Handle方式可以参考：[k8s-webhook-example](https://github.com/slok/k8s-webhook-example)

本项目使用的是`mux.HandleFunc("path", common_func_name)`, 可以将一个普通函数当作http的handler使用，原理是通过适配器对`mux.Handle("path", handler)`封装了一层。

两种方式的关键逻辑都在于Handler对象/common func实现。
### 使用步骤
```
#!/usr/bin/env bash
实例化webhook模版文件
# make webhook

制作webhook service镜像
# make image

部署webhook
make deploy
```

### 测试
[create nginx deployment](https://github.com/leemingeer/webhook-simple/example)