FROM golang:1.16-alpine
WORKDIR /app
COPY . .
ENV GOPROXY=https://goproxy.cn,direct

RUN go mod tidy
RUN go build -o webhook cmd/main.go
CMD ["/app/webhook"]
