FROM debian:jessie
RUN apt-get update && apt-get install -y openssl

ADD generate.sh /bin/

WORKDIR /app

CMD ["/bin/generate.sh"]
