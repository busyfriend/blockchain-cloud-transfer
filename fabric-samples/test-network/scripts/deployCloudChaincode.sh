CHANNEL_NAME_1="mychannel13"
CHANNEL_NAME_2="mychannel24"
CC_SRC_LANGUAGE="golang"
VERSION="1"
DELAY="3"
MAX_RETRY="5"
VERBOSE="false"
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

FABRIC_CFG_PATH=$PWD/../config/

if [ "$CC_SRC_LANGUAGE" = "go" -o "$CC_SRC_LANGUAGE" = "golang" ] ; then
	CC_RUNTIME_LANGUAGE=golang
	CC_SRC_PATH="../chaincode/cloud/go"

	echo Vendoring Go dependencies ...
	pushd ../chaincode/cloud/go
	GO111MODULE=on go mod vendor
	popd
	echo Finished vendoring Go dependencies
  echo
  echo
fi

# import utils
. scripts/envVar.sh


packageChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode package cloud.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label cloud_${VERSION} >&log.txt
  set +x
  res=$?
  cat log.txt
  verifyResult $res "Chaincode packaging on peer0.org${ORG} has failed"
  echo "===================== Chaincode is packaged on peer0.org${ORG} ===================== "
  echo
}

# installChaincode PEER ORG
installChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode install cloud.tar.gz >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode installation on peer0.org${ORG} has failed"
  echo "===================== Chaincode is installed on peer0.org${ORG} ===================== "
  echo
}

# queryInstalled PEER ORG
queryInstalled() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
	PACKAGE_ID=$(sed -n "/cloud_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0.org${ORG} has failed"
  echo "===================== Query installed successful on peer0.org${ORG} on channel ===================== "
  echo
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  ORG=$1
  setGlobals $ORG
  if [ "$ORG" == "1" -o "$ORG" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
	elif [ "$ORG" == "2" -o "$ORG" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
	fi
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.cloud.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name cloud --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION} >&log.txt
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  if [ "$ORG" == "1" -o "$ORG" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
	elif [ "$ORG" == "2" -o "$ORG" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
	fi
  echo "===================== Checking the commit readiness of the chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to check the commit readiness of the chaincode definition on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name cloud --version ${VERSION} --sequence ${VERSION} --output json --init-required >&log.txt
    res=$?
    set +x
    let rc=0
    for var in "$@"
    do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
		COUNTER=$(expr $COUNTER + 1)
	done
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Check commit readiness result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  if [ "$1" == "1" -o "$1" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
	elif [ "$1" == "2" -o "$1" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
	fi
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.cloud.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name cloud $PEER_CONN_PARMS --version ${VERSION} --sequence ${VERSION} --init-required >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
  echo
}

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  if [ "$ORG" == "1" -o "$ORG" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
	elif [ "$ORG" == "2" -o "$ORG" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
	fi
  EXPECTED_RESULT="Version: ${VERSION}, Sequence: ${VERSION}, Endorsement Plugin: escc, Validation Plugin: vscc"
  echo "===================== Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name cloud >&log.txt
    res=$?
    set +x
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: [0-9], Sequence: [0-9], Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query chaincode definition result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

copyGCScredsToDocker(){
  for i in 1 2 3 4; do
    CONTAINER=$(docker ps -f name="dev-peer0.org$i.cloud.com" | awk 'NR==2{print $1}')
    docker cp /home/busyfriend/go/service_account.json $CONTAINER:/home/
  done
}

chaincodeInvokeInit() {
  if [ "$1" == "1" -o "$1" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
    parsePeerConnectionParameters 1 3
    OrgList=(1 3)
	elif [ "$1" == "2" -o "$1" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
    parsePeerConnectionParameters 2 4
    OrgList=(2 4)
	fi
  FILEDIRECTORYPATH="/home/busyfriend/go/src/github.com/hyperledger/fabric-samples/abc___jpg"
  FILEDIRECTORY=$(basename $FILEDIRECTORYPATH)
  for i in "${OrgList[@]}"; do
    ORG=$i
    setGlobals $ORG
    res=$?
    verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
    CONTAINERNAME=$(docker ps -f name="dev-peer0.org$ORG.cloud.com" | awk 'NR==2{print $1}')
    docker cp $FILEDIRECTORYPATH/ $CONTAINERNAME:/home/$FILEDIRECTORY/ >&log.txt
  done    
  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.cloud.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n cloud $PEER_CONN_PARMS --isInit -c '{"function":"InitLedger","Args":[]}' >&log.txt
  set +x
  res=$?
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

uploadDataToCloud() {
  if [ "$1" == "1" -o "$1" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
    parsePeerConnectionParameters 1 3
    OrgList=(1 3)
	elif [ "$1" == "2" -o "$1" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
    parsePeerConnectionParameters 2 4
    OrgList=(2 4)
	fi
  if [ "$2" == "" ]; then
    set -x
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.cloud.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n cloud $PEER_CONN_PARMS --isInit -c '{"Args":["UploadData"]}' >&log.txt
    set +x
    return
  fi
  FILEDIRECTORYPATH=$2
  FILEDIRECTORY=$(basename $FILEDIRECTORYPATH)
  IFS='___' read -ra FILEDIRECTORY_1 <<<$FILEDIRECTORY
  OWNER=$3
  IFS=', ' read -r -a array <<< $4
  mkdir /home/busyfriend/go/$FILEDIRECTORY
  for i in "${array[@]}"; do
    for j in "${OrgList[@]}"; do
      ORG=$j
      setGlobals $ORG
      res=$?
      verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
      CONTAINERNAME=$(docker ps -f name="dev-peer0.org$ORG.cloud.com" | awk 'NR==2{print $1}')
      docker cp /home/busyfriend/go/$FILEDIRECTORY $CONTAINERNAME:/home/
      docker cp $FILEDIRECTORYPATH/$FILEDIRECTORY_1"_"$i $CONTAINERNAME:/home/$FILEDIRECTORY/ >&log.txt
    done
    set -x
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.cloud.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n cloud $PEER_CONN_PARMS -c '{"Args":["UploadData","'DATA1$i'","'$OWNER'","'/home/$FILEDIRECTORY'","'$i'"]}' >&log.txt
    set +x
  done
  rmdir /home/busyfriend/go/$FILEDIRECTORY
  res=$?
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}


while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -c1 )
    CHANNEL_NAME_1="$2"
    shift
    ;;
  -c2 )
    CHANNEL_NAME_2="$2"
    shift
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    DELAY="$2"
    shift
    ;;
  -l )
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -v )
    VERSION="$2"
    shift
    ;;
  -verbose )
    VERBOSE="$2"
    shift
    ;;
  * )
    echo
    echo "Unknown flag: $key"
    exit 1
    ;;
  esac
  shift
done



# at first we package the chaincode
packageChaincode 1
#
# Install chaincode on peer0.org1 and peer0.org2
echo "Installing chaincode on all peers"
installChaincode 1
installChaincode 2
installChaincode 3
installChaincode 4
# query whether the chaincode is installed
queryInstalled 1

# approve the definition for org1
approveForMyOrg 1
# check whether the chaincode definition is ready to be committed expect org1 to have approved and org3 not to
checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org3MSP\": false"
checkCommitReadiness 3 "\"Org1MSP\": true" "\"Org3MSP\": false"
#now approve also for org3
approveForMyOrg 3
# check whether the chaincode definition is ready to be committed expect them both to have approved
checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org3MSP\": true"
checkCommitReadiness 3 "\"Org1MSP\": true" "\"Org3MSP\": true"
# now that we know for sure both orgs have approved, commit the definition
commitChaincodeDefinition 1 3
#query on both orgs to see that the definition committed successfully
queryCommitted 1
queryCommitted 3

# approve the definition for org2
approveForMyOrg 2
# check whether the chaincode definition is ready to be committed expect org2 to have approved and org4 not to
checkCommitReadiness 2 "\"Org2MSP\": true" "\"Org4MSP\": false"
checkCommitReadiness 4 "\"Org2MSP\": true" "\"Org4MSP\": false"
#now approve also for org4
approveForMyOrg 4
# check whether the chaincode definition is ready to be committed expect them both to have approved
checkCommitReadiness 2 "\"Org2MSP\": true" "\"Org4MSP\": true"
checkCommitReadiness 4 "\"Org2MSP\": true" "\"Org4MSP\": true"
# now that we know for sure both orgs have approved, commit the definition
commitChaincodeDefinition 2 4
#query on both orgs to see that the definition committed successfully
queryCommitted 2
queryCommitted 4


#Copy cloud creds to docker containers
copyGCScredsToDocker
# Invoke the chaincode
chaincodeInvokeInit 1
chaincodeInvokeInit 2
uploadDataToCloud 1
uploadDataToCloud 2

exit 0
