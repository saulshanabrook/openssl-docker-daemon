# `openssl-docker-dameon`

Use this for genereating [authentication for a Docker daemon](https://docs.docker.com/engine/articles/https/).


```bash
# set HOST to the DNS name. If your host doesn't have one, just leave it off
# set IPS to a comma seperated list of additional IP addresses it should be
# accessible on. Leave off or blank only allow hostname
$ docker run --rm -v $PWD:/app -e HOST=your.host.com -e IPS="10.10.10.20,127.0.0.1" saulshanabrook/openssl-docker-daemon
+ your.host.com
set -o verbose

echo ${HOST:=no_dns}
+ echo your.host.com

PASS_PHRASE=$(openssl rand -base64 32)
+ openssl rand -base64 32
+ PASS_PHRASE=bTW5imjnyMHi5+mKnP7rg0Qhcn6II/eCv9r71Ol4m4M=

openssl genrsa \
  -aes256 \
  -out ca-key.pem \
  -passout pass:${PASS_PHRASE} \
  4096
+ openssl genrsa -aes256 -out ca-key.pem -passout pass:bTW5imjnyMHi5+mKnP7rg0Qhcn6II/eCv9r71Ol4m4M= 4096
Generating RSA private key, 4096 bit long modulus
............................................................................................................................................................................................................................++
.....................++
e is 65537 (0x10001)

openssl req \
  -new \
  -x509 \
  -days 365 \
  -key ca-key.pem \
  -sha256 \
  -out ca.pem \
  -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$HOST" \
  -passin pass:${PASS_PHRASE}
+ openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem -subj /C=US/ST=Denial/L=Springfield/O=Dis/CN=your.host.com -passin pass:bTW5imjnyMHi5+mKnP7rg0Qhcn6II/eCv9r71Ol4m4M=


openssl genrsa -out server-key.pem 4096
+ openssl genrsa -out server-key.pem 4096
Generating RSA private key, 4096 bit long modulus
.....++
..................................++
e is 65537 (0x10001)

openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
+ openssl req -subj /CN=your.host.com -sha256 -new -key server-key.pem -out server.csr


if test -n "${IPS:-}"; then
  echo subjectAltName = IP:$(echo $IPS | sed -e "s/,/,IP:/g") > extfile.cnf
else
  echo > extfile.cnf
fi
+ test -n 10.10.10.20,127.0.0.1
+ echo 10.10.10.20,127.0.0.1
+ sed -e s/,/,IP:/g
+ echo subjectAltName = IP:10.10.10.20,IP:127.0.0.1

openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
 -CAcreateserial -out server-cert.pem -extfile extfile.cnf -passin pass:${PASS_PHRASE}
+ openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf -passin pass:bTW5imjnyMHi5+mKnP7rg0Qhcn6II/eCv9r71Ol4m4M=
Signature ok
subject=/CN=your.host.com
Getting CA Private Key

openssl genrsa -out key.pem 4096
+ openssl genrsa -out key.pem 4096
Generating RSA private key, 4096 bit long modulus
......................................................................................................++
.....................................................++
e is 65537 (0x10001)

openssl req -subj '/CN=client' -new -key key.pem -out client.csr
+ openssl req -subj /CN=client -new -key key.pem -out client.csr

echo extendedKeyUsage = clientAuth > extfile.cnf
+ echo extendedKeyUsage = clientAuth

openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile.cnf -passin pass:${PASS_PHRASE}
+ openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf -passin pass:bTW5imjnyMHi5+mKnP7rg0Qhcn6II/eCv9r71Ol4m4M=
Signature ok
subject=/CN=client
Getting CA Private Key

rm client.csr server.csr extfile.cnf ca.srl ca-key.pem
+ rm client.csr server.csr extfile.cnf ca.srl ca-key.pem
```

We have now generated the proper certs

```bash
$ ls
ca.pem          cert.pem        key.pem         server-cert.pem server-key.pem
```

And can start a docker daemon that requires authentication

```bash
$ docker daemon --tlsverify --tlscacert=ca.pem --tlscert=server-cert.pem --tlskey=server-key.pem \
  -H=0.0.0.0:2376
```

And then connect to it, by either it's IP or hostname

```bash
$ docker --tlsverify --tlscacert=ca.pem --tlscert=cert.pem --tlskey=key.pem \
  -H=$HOST:2376 version 
```
