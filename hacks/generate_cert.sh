#!/bin/sh

# 1. 生成CA证书及私钥
#  generate ca key(ca-key.pem) and ca cert(ca-cert.pem)
## ca-key.pem
openssl genrsa -out ca-key.pem 1024
##  ca-csr.pem
openssl req -new -key ca-key.pem -out ca-csr.pem
## ca-key.pem + ca-key.pem =>  ca-cert.pem
openssl x509 -req -days 3650 -in ca-csr.pem -signkey ca-key.pem -out ca-cert.pem

#  client and server使用同一个  -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial

# 2. 生成服务端证书及私钥
# generate  server  key
openssl genrsa -out server-key.pem 1024
# generate server-csr.pem
openssl req -new -key server-key.pem -config openssl.cnf -out server-csr.pem


# No template, please set one up. 要至少输入一个

# generate  server-cert.pem,
openssl x509 -req -days 730 -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -in server-csr.pem -out server-cert.pem -extensions v3_req -extfile openssl.cnf

# 3. 生成客户端证书及私钥
openssl genrsa -out client-key.pem
openssl req -new -key client-key.pem -out client-csr.pem
openssl x509 -req -days 365 -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -in client-csr.pem -out client-cert.pem