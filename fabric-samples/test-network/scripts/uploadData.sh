CHANNEL_NAME_1="mychannel13"
CHANNEL_NAME_2="mychannel24"

export FABRIC_CFG_PATH=$PWD/../config/
. scripts/envVar.sh

uploadDataToCloud() {
  if [ "$1" == "1" -o "$1" == "3" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_1
    KEY_PREFIX="c1"
    parsePeerConnectionParameters 1 3
    OrgList=(1 3)
	elif [ "$1" == "2" -o "$1" == "4" ]; then
		CHANNEL_NAME=$CHANNEL_NAME_2
    KEY_PREFIX="c2"
    parsePeerConnectionParameters 2 4
    OrgList=(2 4)
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
      docker cp $FILEDIRECTORYPATH/$FILEDIRECTORY_1"_"$i $CONTAINERNAME:/home/$FILEDIRECTORY/ >&log.tx
    done
    set -x
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.cloud.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n cloud $PEER_CONN_PARMS -c '{"Args":["UploadData","'${KEY_PREFIX}DATA1$i'","'$OWNER'","'/home/$FILEDIRECTORY'","'$i'"]}' >&log.txt
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
  -path )
    PATH_DIRECTORY="$2"
    shift
    ;;
  -owner )
    OWNER="$2"
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



chunks=$(ls -1 $PATH_DIRECTORY | wc -l)
brk_point=`expr $chunks / 2 - 1`
#echo $brk_point
arr=($(printf "%d\n" $(seq 1 $chunks) | shuf))
#echo ${arr[@]}
for i in $(seq 0 $brk_point); do
    chunk_1+="${arr[$i]},"
done
brk_point=`expr $brk_point + 1`
for i in $(seq $brk_point $chunks); do
    chunk_2+="${arr[$i]},"
done
chunk_1=$(echo "$chunk_1" | sed 's/\(.*\),/\1 /')
chunk_2=$(echo "$chunk_2" | sed 's/\(.*\),,/\1 /')

uploadDataToCloud 3 $PATH_DIRECTORY $OWNER $chunk_1
uploadDataToCloud 4 $PATH_DIRECTORY $OWNER $chunk_2

echo "Uploaded $chunk_1 chunks to orgs in $CHANNEL_NAME_1"
echo "Uploaded $chunk_2 chunks to orgs in $CHANNEL_NAME_2"

