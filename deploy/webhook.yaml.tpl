---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ming-webhook-sa
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ming-webhook-crole
rules:
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations"]
  verbs: ["create", "deletecollection"]
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["validatingwebhookconfigurations"]
  verbs: ["create", "deletecollection"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ming-webhook
subjects:
- kind: ServiceAccount
  name: ming-webhook-sa
  namespace: default
  apiGroup: ""
roleRef:
  kind: ClusterRole
  name: ming-webhook-crole
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ming-webhook
  namespace: default
  labels:
    app: ming-webhook
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ming-webhook
  template:
    metadata:
      labels:
        app: ming-webhook
    spec:
      serviceAccountName: ming-webhook-sa
      containers:
        - name: ming-webhook-server
          image: leemingeer/webhook:v1
          imagePullPolicy: IfNotPresent
          args:
            - -tlsCertPath=/etc/webhook/certs/tls.crt
            - -tlsKeyPath=/etc/webhook/certs/tls.key
            - -logtostderr=true
            - -port=8080
            - -v=5
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
            - name: metrics
              containerPort: 8081
              protocol: TCP
          volumeMounts:
            - name: webhook-certs
              mountPath: /etc/webhook/certs
              readOnly: true
          resources:
            requests:
              cpu: 100m
              memory: "128Mi"
            limits:
              cpu: 200m
              memory: "256Mi"
      volumes:
        - name: webhook-certs
          secret:
            secretName: ming-webhook-svc-certs
---
apiVersion: v1
kind: Service
metadata:
  name: ming-webhook-svc
  namespace: default
  labels:
    app: ming-webhook
spec:
  ports:
  - name: http
    port: 443
    targetPort: 8080
  - name: metrics
    port: 8081
    targetPort: 8081
  selector:
    app: ming-webhook
---
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: ming-webhook-mutator
  labels:
    app: ming-mutator
webhooks:
  - name: ming-mutator.default.svc.cluster.local
    admissionReviewVersions: ["v1"]
    sideEffects: None
    failurePolicy: Fail
    clientConfig:
      caBundle: CA_BUNDLE_PLACEMENT
      service:
        name: ming-webhook-svc
        namespace: default
        path: "/mutating"
        port: 443
    rules:
      - operations: ["CREATE"]
        apiGroups: ["apps", "extensions", ""]
        apiVersions: ["v1", "v1beta1"]
        resources: ["deployments","services"]
    timeoutSeconds: 30
    namespaceSelector:
      matchLabels:
        ming-mutator: enabled