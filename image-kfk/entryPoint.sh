#!/bin/bash

#set -x

DIR_KRAFT="/kafka/kraft"
DIR_KFK="/kafka/bin/server/kafka"
KRAFT_CONFIG="${DIR_KRAFT}/kraft.properties"

export JAVA_HOME=$(find /kafka/bin/java/ -maxdepth 1 -name '*jdk*' -type d)
export PATH=${PATH}:${JAVA_HOME}/bin

for jar in /kafka/libs/*.jar
do
	cpJar2LibDir=/kafka/bin/server/kafka/libs
	echo "Duplicating [${jar}] to [${cpJar2LibDir}]"
	cp -f ${jar} ${cpJar2LibDir}
done

if [ 0 -eq "${#}" ]
then
	echo "No command to entrypoint..."
else
	cmd="${1}"
	shift
	case "${cmd}" in
		kraft)
			if [ -z "${KAFKA_CLUSTER_ID}" ]
			then
				echo "No KAFKA Cluster ID defined, stopping"
				echo "Run : kafka-storage.sh random-uuid to get one"
				echo "Here is the result of the command for this time:"
				${DIR_KFK}/bin/kafka-storage.sh random-uuid
			else
				echo "Starting Kafka..."
				if [ ! -e "${KRAFT_CONFIG}" ]
				then
					echo "EntryPoint Init for [${DIR_KRAFT}] with UUID [${KAFKA_CLUSTER_ID}]"
					mkdir -p "${DIR_KRAFT}"
					cp ${DIR_KFK}/config/kraft/server.properties ${KRAFT_CONFIG}
					/configIni.sh KRAFT ${KRAFT_CONFIG}
				fi
				if [ 0 -lt "$(${DIR_KFK}/bin/kafka-storage.sh info -c ${KRAFT_CONFIG} | grep -c "not formatted")" ]
				then
					${DIR_KFK}/bin/kafka-storage.sh format -t "$KAFKA_CLUSTER_ID" -c ${KRAFT_CONFIG}
				fi
				exec "${DIR_KFK}/bin/kafka-server-start.sh" "${KRAFT_CONFIG}"
			fi
			;;
		mm2)
			echo "Starting mm2..."
			exec "${DIR_KFK}/bin/connect-mirror-maker.sh" "/kafka/mm2/mm2.properties"
			;;
		connect)
			echo "Launching Kafka Connect Node"
			exec "${DIR_KFK}/bin/connect-distributed.sh" "/kafka/connect/connect-distributed.properties"
			;;
		shell)
			echo "Entering shell (bash)"
			export PATH=${DIR_KFK}/bin:${PATH}
			exec bash
			;;
		*)
			echo "unknown command... [${cmd}|${@}]"
			exec "${cmd}" ${@}
			;;
	esac
fi

exit 1

