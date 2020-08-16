#!/bin/bash


CHANNEL_NAME_1="$1"
CHANNEL_NAME_2="$2"
DELAY="$3"
MAX_RETRY="$4"
VERBOSE="$5"
: ${CHANNEL_NAME_1:="mychannel13"}
: ${CHANNEL_NAME_2:="mychannel24"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

# import utils
. scripts/envVar.sh

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelTx() {

	set -x
	configtxgen -profile Orgs13Channel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME_1}.tx -channelID $CHANNEL_NAME_1
	configtxgen -profile Orgs24Channel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME_2}.tx -channelID $CHANNEL_NAME_2
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate channel configuration transaction..."
		exit 1
	fi
	echo

}

createAncorPeerTx() {

	for orgmsp in Org1MSP Org3MSP; do

	echo "#######    Generating anchor peer update transaction for ${orgmsp}  ##########"
	set -x
	configtxgen -profile Orgs13Channel -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME_1 -asOrg ${orgmsp}
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate anchor peer update transaction for ${orgmsp}..."
		exit 1
	fi
	echo
	done

	for orgmsp in Org2MSP Org4MSP; do

	echo "#######    Generating anchor peer update transaction for ${orgmsp}  ##########"
	set -x
	configtxgen -profile Orgs24Channel -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME_2 -asOrg ${orgmsp}
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate anchor peer update transaction for ${orgmsp}..."
		exit 1
	fi
	echo
	done
}

createChannel() {
	setGlobals 1
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME_1 --ordererTLSHostnameOverride orderer.cloud.com -f ./channel-artifacts/${CHANNEL_NAME_1}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME_1}.block --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	setGlobals 2
	local rc1=1
	local COUNTER1=1
	while [ $rc1 -ne 0 -a $COUNTER1 -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME_2 --ordererTLSHostnameOverride orderer.cloud.com -f ./channel-artifacts/${CHANNEL_NAME_2}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME_2}.block --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		set +x
		let rc1=$res
		COUNTER1=$(expr $COUNTER1 + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo
	echo "===================== Channel '$CHANNEL_NAME_1' and '$CHANNEL_NAME_2' created ===================== "
	echo
}

# queryCommitted ORG
joinChannel() {
  ORG=$1
  setGlobals $ORG
	if [ "$ORG" == "1" -o "$ORG" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
	elif [ "$ORG" == "2" -o "$ORG" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
	fi
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	echo
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

updateAnchorPeers() {
  ORG=$1
  setGlobals $ORG
	if [ "$ORG" == "1" -o "$ORG" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
	elif [ "$ORG" == "2" -o "$ORG" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
	fi
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
		peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.cloud.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
  verifyResult $res "Anchor peer update failed"
  echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
  sleep $DELAY
  echo
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

FABRIC_CFG_PATH=${PWD}/configtx

## Create channeltx
echo "### Generating channel create transaction '${CHANNEL_NAME_1}.tx' and '${CHANNEL_NAME_2}.tx' ###"
createChannelTx

## Create anchorpeertx
echo "### Generating anchor peer update transactions ###"
createAncorPeerTx

FABRIC_CFG_PATH=$PWD/../config/

## Create channel
echo "Creating channel '$CHANNEL_NAME_1' and '$CHANNEL_NAME_2'"
createChannel

## Join all the peers to the channel
echo "Join Org1 peers to the channel..."
joinChannel 1
echo "Join Org2 peers to the channel..."
joinChannel 2
echo "Join Org3 peers to the channel..."
joinChannel 3
echo "Join Org4 peers to the channel..."
joinChannel 4

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
updateAnchorPeers 1
echo "Updating anchor peers for org2..."
updateAnchorPeers 2
echo "Updating anchor peers for org3..."
updateAnchorPeers 3
echo "Updating anchor peers for org4..."
updateAnchorPeers 4

echo
echo "========= Channel successfully joined =========== "
echo

exit 0
