package webhook

import (
	"context"
	"crypto/sha256"
	"crypto/tls"
	"net/http"

	"encoding/json"
	"fmt"
	"github.com/ghodss/yaml"
	"github.com/golang/glog"
	"io/ioutil"
	"k8s.io/api/admission/v1beta1"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"

	"strings"
	"sync"
)

const (
	admissionWebhookAnnotationMutateKey   = "admission-webhook-example.ming.com/mutate"
	admissionWebhookAnnotationStatusKey   = "admission-webhook-example.ming.com/status"
)

var (
	once   sync.Once
	ws     *webHookServer
	err    error
	runtimeScheme = runtime.NewScheme()
	codecs        = serializer.NewCodecFactory(runtimeScheme)
	deserializer  = codecs.UniversalDeserializer()
	defaulter = runtime.ObjectDefaulter(runtimeScheme)
)

var (
	ignoredNamespaces = []string{
		metav1.NamespacePublic,
	}
)

func NewWebhookServer(webHook WebHookServerParameters) (WebHookServerInt, error) {
	once.Do(func() {
		ws, err = newWebHookServer(webHook)
	})
	return ws, err
}


func newWebHookServer(webHook WebHookServerParameters) (*webHookServer, error) {
	// load tls cert/key file
	tlsCertKey, err := tls.LoadX509KeyPair(webHook.CertFile, webHook.KeyFile)
	if err != nil {
		return nil, err
	}

	ws := &webHookServer{
		server: &http.Server{
			Addr:      fmt.Sprintf(":%v", webHook.Port),
			TLSConfig: &tls.Config{Certificates: []tls.Certificate{tlsCertKey}},
		},
	}

	sidecarConfig, err := loadConfig(webHook.SidecarCfgFile)
	if err != nil {
		return nil, err
	}

	// add routes
	mux := http.NewServeMux()
	mux.HandleFunc("/mutating", ws.serve)
	mux.HandleFunc("/validating", ws.serve)
	ws.server.Handler = mux
	ws.sidecarConfig = sidecarConfig
	return ws, nil
}


// Serve method for webhook server
func (whsvr *webHookServer) serve(w http.ResponseWriter, r *http.Request) {
	var body []byte
	if r.Body != nil {
		if data, err := ioutil.ReadAll(r.Body); err == nil {
			body = data
		}
	}
	if len(body) == 0 {
		glog.Error("empty body")
		http.Error(w, "empty body", http.StatusBadRequest)
		return
	}

	// verify the content type is accurate
	contentType := r.Header.Get("Content-Type")
	if contentType != "application/json" {
		glog.Errorf("Content-Type=%s, expect application/json", contentType)
		http.Error(w, "invalid Content-Type, expect `application/json`", http.StatusUnsupportedMediaType)
		return
	}

	var admissionResponse *v1beta1.AdmissionResponse
	ar := v1beta1.AdmissionReview{}

	if _, _, err := deserializer.Decode(body, nil, &ar); err != nil {
		glog.Errorf("Can't decode body: %v", err)
		admissionResponse = &v1beta1.AdmissionResponse{
			Result: &metav1.Status{
				Message: err.Error(),
			},
		}
	} else {
		fmt.Println(r.URL.Path)
		if r.URL.Path == "/mutating" {
			admissionResponse = whsvr.mutating(&ar)
		} else if r.URL.Path == "/validating" {
			admissionResponse = whsvr.validating(&ar)
		}
	}

	admissionReview := v1beta1.AdmissionReview{}
	if admissionResponse != nil {
		admissionReview.Response = admissionResponse
		if ar.Request != nil {
			admissionReview.Response.UID = ar.Request.UID
		}
	}

	resp, err := json.Marshal(admissionReview)
	if err != nil {
		glog.Errorf("Can't encode response: %v", err)
		http.Error(w, fmt.Sprintf("could not encode response: %v", err), http.StatusInternalServerError)
	}
	glog.Infof("Ready to write reponse ...")
	if _, err := w.Write(resp); err != nil {
		glog.Errorf("Can't write response: %v", err)
		http.Error(w, fmt.Sprintf("could not write response: %v", err), http.StatusInternalServerError)
	}
}

func (ws *webHookServer) Start() {
	if err := ws.server.ListenAndServeTLS("", ""); err != nil {
		glog.Errorf("Failed to listen and serve webhook server: %v", err)
	}
}

func (ws *webHookServer) Stop() {
	glog.Infof("Got OS shutdown signal, shutting down wenhook server gracefully...")
	ws.server.Shutdown(context.Background())
}


// main mutation process
func (whsvr *webHookServer) mutating(ar *v1beta1.AdmissionReview) *v1beta1.AdmissionResponse {
	req := ar.Request
	var (
		availableAnnotations map[string]string


		deployment appsv1.Deployment
	)


	glog.Infof("AdmissionReview for Kind=%v, Namespace=%v Name=%v (%v) UID=%v patchOperation=%v UserInfo=%v",
		req.Kind, req.Namespace, req.Name, req.UID, req.Operation, req.UserInfo)

	switch req.Kind.Kind {
	case "Deployment":

		if err := json.Unmarshal(req.Object.Raw, &deployment); err != nil {
			glog.Errorf("Could not unmarshal raw object: %v", err)
			return &v1beta1.AdmissionResponse{
				Result: &metav1.Status{
					Message: err.Error(),
				},
			}
		}


	case "Service":
		var service corev1.Service
		if err := json.Unmarshal(req.Object.Raw, &service); err != nil {
			glog.Errorf("Could not unmarshal raw object: %v", err)
			return &v1beta1.AdmissionResponse{
				Result: &metav1.Status{
					Message: err.Error(),
				},
			}
		}
	}

	// 策略设置
	//if !mutationRequired(ignoredNamespaces, objectMeta) {
	//	glog.Infof("Skipping validation for %s/%s due to policy check", resourceNamespace, resourceName)
	//	return &v1beta1.AdmissionResponse{
	//		Allowed: true,
	//	}
	//}

	// 这是容器及其卷
	//applyDefaultsWorkaround(whsvr.sidecarConfig.Containers, whsvr.sidecarConfig.Volumes)
	annotations := map[string]string{admissionWebhookAnnotationStatusKey: "mutated"}
	patchBytes, err := createPatch(availableAnnotations, annotations)
	if err != nil {
		return &v1beta1.AdmissionResponse{
			Result: &metav1.Status{
				Message: err.Error(),
			},
		}
	}

	glog.Infof("AdmissionResponse: patch=%v\n", string(patchBytes))
	return &v1beta1.AdmissionResponse{
		Allowed: true,
		Patch:   patchBytes,
		PatchType: func() *v1beta1.PatchType {
			pt := v1beta1.PatchTypeJSONPatch
			return &pt
		}(),
	}
}


// validate deployments and services
func (whsvr *webHookServer) validating(ar *v1beta1.AdmissionReview) *v1beta1.AdmissionResponse {
	result := &metav1.Status{
		Reason: "required labels are not set",
	}
	return &v1beta1.AdmissionResponse{
		Allowed: true,
		Result:  result,
	}
}

func loadConfig(configFile string) (*Config, error) {
	data, err := ioutil.ReadFile(configFile)
	if err != nil {
		return nil, err
	}
	glog.Infof("New configuration: sha256sum %x", sha256.Sum256(data))

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}

	return &cfg, nil
}

func mutationRequired(ignoredList []string, metadata *metav1.ObjectMeta) bool {
	required := admissionRequired(ignoredList, admissionWebhookAnnotationMutateKey, metadata)
	annotations := metadata.GetAnnotations()
	if annotations == nil {
		annotations = map[string]string{}
	}
	status := annotations[admissionWebhookAnnotationStatusKey]

	if strings.ToLower(status) == "mutated" {
		required = false
	}

	glog.Infof("Mutation policy for %v/%v: required:%v", metadata.Namespace, metadata.Name, required)
	return required
}


func admissionRequired(ignoredList []string, admissionAnnotationKey string, metadata *metav1.ObjectMeta) bool {
	// skip special kubernetes system namespaces
	for _, namespace := range ignoredList {
		if metadata.Namespace == namespace {
			glog.Infof("Skip validation for %v for it's in special namespace:%v", metadata.Name, metadata.Namespace)
			return false
		}
	}

	annotations := metadata.GetAnnotations()
	if annotations == nil {
		annotations = map[string]string{}
	}

	var required bool
	switch strings.ToLower(annotations[admissionAnnotationKey]) {
	default:
		required = true
	case "n", "no", "false", "off":
		required = false
	}
	return required
}

func applyDefaultsWorkaround(containers []corev1.Container, volumes []corev1.Volume) {
	defaulter.Default(&corev1.Pod {
		Spec: corev1.PodSpec {
			Containers:     containers,
			Volumes:        volumes,
		},
	})
}

func createPatch(availableAnnotations map[string]string, annotations map[string]string) ([]byte, error) {
	var patch []patchOperation
	patch = append(patch, updateAnnotation(availableAnnotations, annotations)...)
	return json.Marshal(patch)
}

func updateAnnotation(target map[string]string, added map[string]string) (patch []patchOperation) {
	for key, value := range added {
		if target == nil || target[key] == "" {
			target = map[string]string{}
			patch = append(patch, patchOperation{
				Op:   "add",
				Path: "/metadata/annotations",
				Value: map[string]string{
					key: value,
				},
			})
		} else {
			patch = append(patch, patchOperation{
				Op:    "replace",
				Path:  "/metadata/annotations/" + key,
				Value: value,
			})
		}
	}
	return patch
}