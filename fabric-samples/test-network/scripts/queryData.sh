CHANNEL_NAME_1="mychannel13"
CHANNEL_NAME_2="mychannel24"
MAX_RETRY="5"
DELAY="3"

export FABRIC_CFG_PATH=$PWD/../config/
. scripts/envVar.sh

chaincodeQuery() {
  ORG=$1
  setGlobals $ORG
  if [ "$1" == "1" -o "$1" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
	elif [ "$1" == "2" -o "$1" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
	fi
  echo "===================== Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n cloud -c '{"Args":["queryData","'$2'"]}' >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

#prefix is used to get the channel id, so that the query is done on that particular channel peers
prefix=$(echo $1 | cut -c1-2)
if [ $prefix == "c1" ]; then
    chaincodeQuery 1 $1
elif [ $prefix == "c2" ]; then
    chaincodeQuery 2 $1
else
    chaincodeQuery 3 $1
fi