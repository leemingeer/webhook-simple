package main

import (
	"flag"
	"fmt"
	"github.com/golang/glog"
	"github.com/leemingeer/webhook-simple/pkg/webhook"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	_ "net/http/pprof"
)

var webHook webhook.WebHookServerParameters

func init() {
	// read parameters
	flag.IntVar(&webHook.Port, "port", 443, "The port of webhook server to listen.")
	flag.StringVar(&webHook.CertFile, "tlsCertPath", "/etc/webhook/certs/cert.pem", "The path of tls cert")
	flag.StringVar(&webHook.KeyFile, "tlsKeyPath", "/etc/webhook/certs/key.pem", "The path of tls key")
	flag.StringVar(&webHook.SidecarCfgFile, "sidecarCfgFile", "/etc/webhook-demo/config/sidecarconfig.yaml", "File containing the mutation configuration.")
}

type Pod struct {
	Metadata struct {
		Name        string            `json:"name"`
		Annotations map[string]string `json:"annotations"`
	} `json:"metadata"`
}

func main() {

	// parse parameters
	flag.Parse()
	defer glog.Flush()
	fmt.Println("this is fmt!")
	glog.CopyStandardLogTo("INFO")
	glog.Info("Begin starting")
	glog.Flush()

	go func() {
		fmt.Println(http.ListenAndServe("localhost:6060", nil))
	}()

	// init webhook api
	ws, err := webhook.NewWebhookServer(webHook)
	if err != nil {
		panic(err)
	}

	// start webhook server in new routine
	go ws.Start()
	glog.Info("Server started")

	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, syscall.SIGINT, syscall.SIGTERM)
	<-signalChan

	ws.Stop()

}
