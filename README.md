
## webhook simple

### 简介
`webhook server`关键流程是通过`http.Server()`对象的`Handler`串接。当`webhook server`收到`kube-apiserver`动态准入控制器发过来的`admission review request`, 其中的path路由匹配到注册到mux的自定义handler对象， 调用其`ServeHttp()`来实现。

http包内置了`http.Server`的Handler实现: `NewServeMux`(简称`mux`), 可将多路自定义handler对象（实现ServeHttp方法）注册到mux的api路由中.

`mux`对外暴露`Handle`和`HandleFunc`两种方式，
- Handle方式 
  - 将handler注册到mux, 有ServeHttp方法的对象才可以称为handler。
- HandleFunc方式
  - 将普通函数注册到mux, 一个普通函数当作http的handler的原因是底层适配器将普通函数封装成了`handler`。

本项目使用的是`mux.HandleFunc`注册方式， Handle注册方式参考：参考：[k8s-webhook-example](https://github.com/slok/k8s-webhook-example)



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
[create nginx deployment](https://github.com/leemingeer/webhook-simple/tree/main/example)