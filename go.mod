module github.com/leemingeer/webhook-simple

go 1.16

require k8s.io/api v0.26.3

require (
	github.com/ghodss/yaml v1.0.0
	github.com/go-logr/logr v1.2.3 // indirect
	github.com/golang/glog v0.0.0-20160126235308-23def4e6c14b
	golang.org/x/net v0.7.0 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
	k8s.io/apimachinery v0.26.3
	k8s.io/klog/v2 v2.80.1 // indirect
	k8s.io/kubernetes v0.0.0-00010101000000-000000000000
	sigs.k8s.io/structured-merge-diff/v4 v4.2.3 // indirect
)

replace (
	github.com/go-logr/logr => github.com/go-logr/logr v0.2.0
	google.golang.org/grpc => google.golang.org/grpc v1.27.0
	k8s.io/api => k8s.io/api v0.20.10
	k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.20.10
	k8s.io/apimachinery => k8s.io/apimachinery v0.20.10
	k8s.io/apiserver => k8s.io/apiserver v0.20.10
	k8s.io/cli-runtime => k8s.io/cli-runtime v0.20.10
	k8s.io/client-go => k8s.io/client-go v0.20.10
	k8s.io/cloud-provider => k8s.io/cloud-provider v0.20.10
	k8s.io/cluster-bootstrap => k8s.io/cluster-bootstrap v0.20.10
	k8s.io/code-generator => k8s.io/code-generator v0.20.10
	k8s.io/component-base => k8s.io/component-base v0.20.10
	k8s.io/component-helpers => k8s.io/component-helpers v0.20.10
	k8s.io/controller-manager => k8s.io/controller-manager v0.20.10
	k8s.io/cri-api => k8s.io/cri-api v0.20.10
	k8s.io/csi-translation-lib => k8s.io/csi-translation-lib v0.20.10
	k8s.io/klog/v2 => k8s.io/klog/v2 v2.4.0

	k8s.io/kube-aggregator => k8s.io/kube-aggregator v0.20.10
	k8s.io/kube-controller-manager => k8s.io/kube-controller-manager v0.20.10
	k8s.io/kube-proxy => k8s.io/kube-proxy v0.20.10
	k8s.io/kube-scheduler => k8s.io/kube-scheduler v0.20.10
	k8s.io/kubectl => k8s.io/kubectl v0.20.10
	k8s.io/kubelet => k8s.io/kubelet v0.20.10
	k8s.io/kubernetes => k8s.io/kubernetes v1.20.10
	k8s.io/legacy-cloud-providers => k8s.io/legacy-cloud-providers v0.20.10
	k8s.io/metrics => k8s.io/metrics v0.20.10
	k8s.io/mount-utils => k8s.io/mount-utils v0.20.10
	k8s.io/pod-security-admission => k8s.io/pod-security-admission v0.20.10
	k8s.io/sample-apiserver => k8s.io/sample-apiserver v0.20.10
	k8s.io/sample-cli-plugin => k8s.io/sample-cli-plugin v0.20.10
	k8s.io/sample-controller => k8s.io/sample-controller v0.20.10
	sigs.k8s.io/controller-runtime => sigs.k8s.io/controller-runtime v0.8.0
)
