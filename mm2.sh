CONF_FOLDER="datas-poc/mm2"
TARGET_HOST="localhost:8083"

function validate_cluster_files() {
  res=1
  if [ ! -f "${CLUSTER_CPC_JSON_PATH}" ]
  then
    echo "Checkpoints conf is missing. Create file ${CLUSTER_CPC_JSON_PATH}"
    res=2
  fi
  if [ ! -f "${CLUSTER_HBC_JSON_PATH}" ]
  then
    echo "Heartbeat conf is missing. Create file ${CLUSTER_HBC_JSON_PATH}"
    res=2
  fi
  if [ ! -f "${CLUSTER_MSC_JSON_PATH}" ]
  then
    echo "Source conf is missing. Create file ${CLUSTER_MSC_JSON_PATH}"
    res=2
  fi

  if [ $res == 2 ]
  then
    exit 1
  fi
}


function deploy_cluster() {
  worker=$1

  find smt/ -path '*/target/*.jar' -exec cp {} datas-poc/smt/ \;

  if [ -z "$worker" -o "cpc" = "$worker" ]
  then
    CPC=$(curl -s http://${TARGET_HOST}/connectors/${CLUSTER_CPC_NAME}/status | jq ".connector.state")
    if [ "$CPC" == '"RUNNING"' ]
    then
      echo "Checkpoints connector already deployed"
    else
      echo "Deploying checkpoints connector"
      curl -X PUT -H "Content-Type: application/json" \
        --data @${CLUSTER_CPC_JSON_PATH} \
        -s -f http://${TARGET_HOST}/connectors/${CLUSTER_CPC_NAME}/config >> /dev/null || \
        echo "ERROR: Failed to deploy checkpoints connector"
    fi
  fi

  if [ -z "$worker" -o "hbc" = "$worker" ]
  then
    HBC=$(curl -s http://${TARGET_HOST}/connectors/${CLUSTER_HBC_NAME}/status | jq ".connector.state")
    if [ "$HBC" == '"RUNNING"' ]
    then
      echo "Heartbeat connector already deployed"
    else
      echo "Deploying heartbeats connector"
      curl -X PUT -s -f -H "Content-Type: application/json" \
        --data @${CLUSTER_HBC_JSON_PATH} \
        http://${TARGET_HOST}/connectors/${CLUSTER_HBC_NAME}/config >> /dev/null || \
        echo "ERROR: Failed to deploy heartbeats connector"
    fi
  fi

  if [ -z "$worker" -o "msc" = "$worker" ]
  then
    MSC=$(curl -s http://${TARGET_HOST}/connectors/${CLUSTER_MSC_NAME}/status | jq ".connector.state")
    if [ "$MSC" == '"RUNNING"' ]
    then
      echo "Source connector already deployed"
    else
      echo "Deploying source connector"
      #curl -X PUT -s -f -H "Content-Type: application/json" \
      curl -X PUT  -H "Content-Type: application/json" \
        --data @${CLUSTER_MSC_JSON_PATH} \
        http://${TARGET_HOST}/connectors/${CLUSTER_MSC_NAME}/config 1>>mm2.log 2>&1 || \
        echo "ERROR: Failed to deploy source connector"
    fi
  fi
}

function undeploy_cluster() {
  worker=$1
  if [ -z "$worker" -o "cpc" = "$worker" ]; then
    curl -X DELETE -s -f http://${TARGET_HOST}/connectors/${CLUSTER_CPC_NAME} || echo "WARN: checkpoints connector not found"
    echo "Checkpoints connector undeployed"
  fi
  if [ -z "$worker" -o "hbc" = "$worker" ]; then
    curl -X DELETE -s -f http://${TARGET_HOST}/connectors/${CLUSTER_HBC_NAME} || echo "WARN: heartbeats connector not found"
    echo "Heartbeats connector undeployed"
  fi
  if [ -z "$worker" -o "msc" = "$worker" ]; then
    curl -X DELETE -s -f http://${TARGET_HOST}/connectors/${CLUSTER_MSC_NAME} || echo "WARN: source connector not found"
    echo "Source connector undeployed"
  fi

}
set -x
action=$1
cluster=$2

if [ -z "$cluster" ]; then
  echo "Cluster is empty"
  exit 1
fi

CLUSTER_FOLDER="${CONF_FOLDER}/${cluster}"
CLUSTER_CPC_NAME="mm2-${cluster}-cpc"
CLUSTER_HBC_NAME="mm2-${cluster}-hbc"
CLUSTER_MSC_NAME="mm2-${cluster}-msc"

CLUSTER_CPC_JSON_PATH="${CLUSTER_FOLDER}/mm2-cpc.json"
CLUSTER_HBC_JSON_PATH="${CLUSTER_FOLDER}/mm2-hbc.json"
CLUSTER_MSC_JSON_PATH="${CLUSTER_FOLDER}/mm2-msc.json"

validate_cluster_files

case $action in

deploy)
  echo "Deploying cluster $cluster"
  deploy_cluster 
  ;;

deploy-cpc)
  echo "Deploying CPC for cluster $cluster"
  deploy_cluster "cpc"
  ;;

deploy-hbc)
  echo "Deploying HBC for cluster $cluster"
  deploy_cluster "hbc"
  ;;

deploy-msc)
  echo "Deploying MSC for cluster $cluster"
  deploy_cluster "msc"
  ;;

undeploy)
  echo "Undeploying cluster $cluster"
  undeploy_cluster 
  ;;

undeploy-CPC)
  echo "Undeploying CPC for cluster $cluster"
  undeploy_cluster "cpc"
  ;;

undeploy-hbc)
  echo "Undeploying HBC for cluster $cluster"
  undeploy_cluster "hbc"
  ;;

undeploy-msc)
  echo "Undeploying MSC for cluster $cluster"
  undeploy_cluster "msc"
  ;;

redeploy)
  echo "Redeploying cluster $cluster"
  undeploy_cluster 
  deploy_cluster 
  ;;

redeploy-msc)
  echo "Redeploying MSC for cluster $cluster"
  undeploy_cluster "msc"
  deploy_cluster "msc"
  ;;

status)
  CPC=$(curl -s http://${TARGET_HOST}/connectors/${CLUSTER_CPC_NAME}/status | jq ".connector.state")
  HBC=$(curl -s http://${TARGET_HOST}/connectors/${CLUSTER_HBC_NAME}/status | jq ".connector.state")
  MSC=$(curl -s http://${TARGET_HOST}/connectors/${CLUSTER_MSC_NAME}/status | jq ".connector.state")
  echo "Checkpoint connector: $CPC"
  echo "Heartbeat connector: $HBC"
  echo "Source connector: $MSC"
  ;;

*)
  echo "usage: mm2.sh [deploy | undeploy | redeploy | status] cluster"
  ;;
esac
