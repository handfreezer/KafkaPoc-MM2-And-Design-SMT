FROM debian:bookworm-20251229

ENV DEBIAN_FRONTEND=noninteractive
ENV KFK_VERSION=4.1.1

RUN apt -y update &&\
	apt -y upgrade &&\
	apt install -y --no-install-recommends \
		vim git curl wget python3 procps kcat ca-certificates

RUN mkdir -p /kafka/bin/server &&\
	cd /kafka/bin/server &&\
	curl -kvO "https://downloads.apache.org/kafka/${KFK_VERSION}/kafka_2.13-${KFK_VERSION}.tgz"  &&\
	tar xzvf kafka*.tgz &&\
	rm -rf kafka*.tgz &&\
	ln -sf /kafka/bin/server/kafka_* /kafka/bin/server/kafka 

RUN mkdir -p /kafka/bin/java &&\
	cd /kafka/bin/java &&\
	curl -kvO "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz" &&\
	tar xzvf openjdk*.tar.gz &&\
	rm -rf openjdk*.tar.gz 	

RUN mkdir -p /kafka/kraft /kafka/logs /kafka/connect /kafka/mm2 /kafka/libs /kafka/acls

VOLUME ["/kafka/kraft"]
VOLUME ["/kafka/logs"]
VOLUME ["/kafka/connect"]
VOLUME ["/kafka/mm2"]
VOLUME ["/kafka/libs"]
VOLUME ["/kafka/acls"]

EXPOSE 9092
EXPOSE 8083

COPY ./entryPoint.sh /entryPoint.sh
COPY ./configIni.sh /configIni.sh
COPY ./testBroker.sh /testBroker.sh

ENTRYPOINT ["/entryPoint.sh"]
CMD ["kraft"]

