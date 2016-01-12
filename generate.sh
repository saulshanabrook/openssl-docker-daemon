#!/bin/sh
set -o errexit
set -o nounset
set -o xtrace
set -o verbose

if test -n "${HOST:-}"; then
  CNHOST="CN=$HOST"
else
  CNHOST=""
fi

PASS_PHRASE=$(openssl rand -base64 32)

openssl genrsa \
  -aes256 \
  -out ca-key.pem \
  -passout "pass:${PASS_PHRASE}" \
  4096

openssl req \
  -new \
  -x509 \
  -days 365 \
  -key ca-key.pem \
  -sha256 \
  -out ca.pem \
  -subj "/C=US/ST=Denial/L=Springfield/O=Dis/${CNHOST}" \
  -passin "pass:${PASS_PHRASE}"


openssl genrsa -out server-key.pem 4096

openssl req -subj "/${CNHOST}" -sha256 -new -key server-key.pem -out server.csr


if test -n "${IPS:-}"; then
  echo "subjectAltName = IP:$(echo $IPS | sed -e 's/,/,IP:/g')" > extfile.cnf
else
  echo > extfile.cnf
fi

openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
 -CAcreateserial -out server-cert.pem -extfile extfile.cnf -passin "pass:${PASS_PHRASE}"

openssl genrsa -out key.pem 4096

openssl req -subj '/CN=client' -new -key key.pem -out client.csr

echo extendedKeyUsage = clientAuth > extfile.cnf

openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile.cnf -passin "pass:${PASS_PHRASE}"

rm client.csr extfile.cnf server.csr ca.srl ca-key.pem
