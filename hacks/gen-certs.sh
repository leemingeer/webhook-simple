#! /bin/bash

WEBHOOK_NS=default
WEBHOOK_NAME=ming-webhook

WEBHOOK_FILE_OUT=../deploy/webhook.yaml
WEBHOOK_CERT_FILE_OUT=../deploy/webhook-certs.yaml

TMPDIR=$(mktemp -d)

# create certs for webhook provider
cat <<EOF >> "${TMPDIR}/csr.conf"
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${WEBHOOK_NAME}
DNS.2 = ${WEBHOOK_NAME}.${WEBHOOK_NS}
DNS.3 = ${WEBHOOK_NAME}.${WEBHOOK_NS}.svc
EOF
openssl genrsa -out "${TMPDIR}/server-key.pem" 2048
openssl req -new -key "${TMPDIR}/server-key.pem" -subj "/CN=${WEBHOOK_NAME}.${WEBHOOK_NS}.svc" -out "${TMPDIR}/server.csr" -config "${TMPDIR}/csr.conf"

CSR="certificatesigningrequests.v1beta1.certificates.k8s.io/${WEBHOOK_NAME}.${WEBHOOK_NS}"

# clean-up any previously created CSR for our service. Ignore errors if not present.
if kubectl get ${CSR}; then
  if kubectl delete ${CSR}; then
    echo "WARN: Previous CSR was found and removed."
  fi
fi

# create server cert/key CSR and send it to K8s api
cat <<EOF | kubectl create --validate=false -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${WEBHOOK_NAME}.${WEBHOOK_NS}
spec:
  groups:
  - system:authenticated
  request: $(base64 < "${TMPDIR}/server.csr" | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

# verify CSR has been created
while true; do
  if kubectl get ${CSR}; then
      break
  fi
done

kubectl certificate approve ${CSR}

# verify certificate has been signed
i=1
while [ "$i" -ne 20 ]
do
  SERVERCERT=$(kubectl get ${CSR} -o jsonpath='{.status.certificate}')
  if [ "${SERVERCERT}" != '' ]; then
      break
  fi
  sleep 3
  i=$((i + 1))
done

echo "${SERVERCERT}" | openssl base64 -d -A -out "${TMPDIR}/server-cert.pem"

# generate the secret with CA cert and server cert/key
kubectl -n ${WEBHOOK_NS} create secret tls \
    ${WEBHOOK_NAME}-certs \
    --key=${TMPDIR}/server-key.pem \
    --cert=${TMPDIR}/server-cert.pem \
    --dry-run=client -o yaml > ${WEBHOOK_CERT_FILE_OUT}

# set the CABundle on the webhook registration
CA_BUNDLE=$(base64 < ${TMPDIR}/server-cert.pem  | tr -d '\n')
sed "s/CA_BUNDLE_PLACEMENT/${CA_BUNDLE}/" ../deploy/webhook.yaml.tpl > ${WEBHOOK_FILE_OUT}

# clean-up
rm -rf ${TMPDIR}
