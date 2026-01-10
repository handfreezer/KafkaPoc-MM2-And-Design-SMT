#!/bin/bash

KafkaConnectExtensions="1.5.0-4.1.1"
KafkaIoConfluentDeps="7.5.1"
KafkaIoConfluentPackages="kafka-schema-registry kafka-schema-registry-client"
ApacheAvro="1.11.3"

modeDev=0
if [ 0 -lt "${#}" ]
then
	modeDev=${1}
fi

./999-reset-poc.sh

rm -f datas-poc/connect/smt/*.jar
rm -f datas-poc/libs/*.jar

(
	cd datas-poc/connect/smt
	if [ 0 -lt "${modeDev}" ]
	then
		cp ~/git/KafkaConnectExtensions/smt/target/ulukai-kafka-connect-smt-${KafkaConnectExtensions}.jar . 1>/dev/null 2>&1
		echo "DEV - SMT > ${?}"
	else
		wget https://github.com/handfreezer/KafkaConnectExtensions/releases/download/${KafkaConnectExtensions}/ulukai-kafka-connect-smt-${KafkaConnectExtensions}.jar 1>/dev/null 2>&1
		echo "SMT > ${?}"
	fi
)
(
	cd datas-poc/libs
	if [ 0 -lt "${modeDev}" ]
	then
		cp ~/git/KafkaConnectExtensions/mirror/target/ulukai-kafka-connect-mirror-${KafkaConnectExtensions}.jar . 1>/dev/null 2>&1
		echo "DEV - Connect-Mirror > ${?}"
		cp ~/git/KafkaConnectExtensions/broker/target/ulukai-kafka-broker-groupkafkaprincipal-${KafkaConnectExtensions}.jar . 1>/dev/null 2>&1
		echo "DEV - GroupsKafkaPrincipals > ${?}"
	else
		wget https://github.com/handfreezer/KafkaConnectExtensions/releases/download/${KafkaConnectExtensions}/ulukai-kafka-connect-mirror-${KafkaConnectExtensions}.jar 1>/dev/null 2>&1
		echo "Mirror > ${?}"
		wget https://github.com/handfreezer/KafkaConnectExtensions/releases/download/${KafkaConnectExtensions}/ulukai-kafka-broker-groupkafkaprincipal-${KafkaConnectExtensions}.jar 1>/dev/null 2>&1
		echo "GroupsKafkaPrincipals > ${?}"
	fi
	wget https://repo1.maven.org/maven2/org/apache/avro/avro/${ApacheAvro}/avro-${ApacheAvro}.jar 1>/dev/null 2>&1
	echo "Avro > ${?}"
	for dep in ${KafkaIoConfluentPackages}
	do
		wget https://packages.confluent.io/maven/io/confluent/${dep}/${KafkaIoConfluentDeps}/${dep}-${KafkaIoConfluentDeps}.jar 1>/dev/null 2>&1
		echo "${dep} > ${?}"
	done
)	

