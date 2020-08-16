

function createOrg1 {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/peerOrganizations/org1.cloud.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org1.cloud.com/
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-org1 --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/org1.cloud.com/msp/config.yaml

  echo
	echo "Register peer0"
  echo
  set -x
	fabric-ca-client register --caname ca-org1 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-org1 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-org1 --id.name org1admin --id.secret org1adminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/org1.cloud.com/peers
  mkdir -p organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com

  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-org1 -M ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/msp --csr.hosts peer0.org1.cloud.com --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/org1.cloud.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-org1 -M ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/tls --enrollment.profile tls --csr.hosts peer0.org1.cloud.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
  set +x


  cp ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/org1.cloud.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org1.cloud.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/org1.cloud.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org1.cloud.com/tlsca/tlsca.org1.cloud.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/org1.cloud.com/ca
  cp ${PWD}/organizations/peerOrganizations/org1.cloud.com/peers/peer0.org1.cloud.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/org1.cloud.com/ca/ca.org1.cloud.com-cert.pem

  mkdir -p organizations/peerOrganizations/org1.cloud.com/users
  mkdir -p organizations/peerOrganizations/org1.cloud.com/users/User1@org1.cloud.com

  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-org1 -M ${PWD}/organizations/peerOrganizations/org1.cloud.com/users/User1@org1.cloud.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

  mkdir -p organizations/peerOrganizations/org1.cloud.com/users/Admin@org1.cloud.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://org1admin:org1adminpw@localhost:7054 --caname ca-org1 -M ${PWD}/organizations/peerOrganizations/org1.cloud.com/users/Admin@org1.cloud.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/org1.cloud.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org1.cloud.com/users/Admin@org1.cloud.com/msp/config.yaml

}


function createOrg2 {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/peerOrganizations/org2.cloud.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org2.cloud.com/
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-org2 --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/org2.cloud.com/msp/config.yaml

  echo
	echo "Register peer0"
  echo
  set -x
	fabric-ca-client register --caname ca-org2 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
  set +x

  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-org2 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
  set +x

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-org2 --id.name org2admin --id.secret org2adminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/org2.cloud.com/peers
  mkdir -p organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com

  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-org2 -M ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/msp --csr.hosts peer0.org2.cloud.com --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/org2.cloud.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-org2 -M ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/tls --enrollment.profile tls --csr.hosts peer0.org2.cloud.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
  set +x


  cp ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/org2.cloud.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org2.cloud.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/org2.cloud.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org2.cloud.com/tlsca/tlsca.org2.cloud.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/org2.cloud.com/ca
  cp ${PWD}/organizations/peerOrganizations/org2.cloud.com/peers/peer0.org2.cloud.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/org2.cloud.com/ca/ca.org2.cloud.com-cert.pem

  mkdir -p organizations/peerOrganizations/org2.cloud.com/users
  mkdir -p organizations/peerOrganizations/org2.cloud.com/users/User1@org2.cloud.com

  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-org2 -M ${PWD}/organizations/peerOrganizations/org2.cloud.com/users/User1@org2.cloud.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
  set +x

  mkdir -p organizations/peerOrganizations/org2.cloud.com/users/Admin@org2.cloud.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://org2admin:org2adminpw@localhost:8054 --caname ca-org2 -M ${PWD}/organizations/peerOrganizations/org2.cloud.com/users/Admin@org2.cloud.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org2/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/org2.cloud.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org2.cloud.com/users/Admin@org2.cloud.com/msp/config.yaml

}

function createOrderer {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/ordererOrganizations/cloud.com

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/cloud.com
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/ordererOrganizations/cloud.com/msp/config.yaml


  echo
	echo "Register orderer"
  echo
  set -x
	fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
    set +x

  echo
  echo "Register the orderer admin"
  echo
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

	mkdir -p organizations/ordererOrganizations/cloud.com/orderers
  mkdir -p organizations/ordererOrganizations/cloud.com/orderers/cloud.com

  mkdir -p organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com

  echo
  echo "## Generate the orderer msp"
  echo
  set -x
	fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/msp --csr.hosts orderer.cloud.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/cloud.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/tls --enrollment.profile tls --csr.hosts orderer.cloud.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/tls/keystore/* ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/tls/server.key

  mkdir ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/msp/tlscacerts/tlsca.cloud.com-cert.pem

  mkdir ${PWD}/organizations/ordererOrganizations/cloud.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/cloud.com/orderers/orderer.cloud.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/cloud.com/msp/tlscacerts/tlsca.cloud.com-cert.pem

  mkdir -p organizations/ordererOrganizations/cloud.com/users
  mkdir -p organizations/ordererOrganizations/cloud.com/users/Admin@cloud.com

  echo
  echo "## Generate the admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/cloud.com/users/Admin@cloud.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/cloud.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/cloud.com/users/Admin@cloud.com/msp/config.yaml


}

function createOrg3 {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/peerOrganizations/org3.cloud.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org3.cloud.com/
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:10054 --caname ca-org3 --tls.certfiles ${PWD}/organizations/fabric-ca/org3/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-org3.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-org3.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-org3.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-org3.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/org3.cloud.com/msp/config.yaml

  echo
	echo "Register peer0"
  echo
  set -x
	fabric-ca-client register --caname ca-org3 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/org3/tls-cert.pem
  set +x

  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-org3 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/org3/tls-cert.pem
  set +x

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-org3 --id.name org3admin --id.secret org3adminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/org3/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/org3.cloud.com/peers
  mkdir -p organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com

  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:10054 --caname ca-org3 -M ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/msp --csr.hosts peer0.org3.cloud.com --tls.certfiles ${PWD}/organizations/fabric-ca/org3/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/org3.cloud.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:10054 --caname ca-org3 -M ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/tls --enrollment.profile tls --csr.hosts peer0.org3.cloud.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/org3/tls-cert.pem
  set +x


  cp ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/org3.cloud.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org3.cloud.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/org3.cloud.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org3.cloud.com/tlsca/tlsca.org3.cloud.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/org3.cloud.com/ca
  cp ${PWD}/organizations/peerOrganizations/org3.cloud.com/peers/peer0.org3.cloud.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/org3.cloud.com/ca/ca.org3.cloud.com-cert.pem

  mkdir -p organizations/peerOrganizations/org3.cloud.com/users
  mkdir -p organizations/peerOrganizations/org3.cloud.com/users/User1@org3.cloud.com

  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:10054 --caname ca-org3 -M ${PWD}/organizations/peerOrganizations/org3.cloud.com/users/User1@org3.cloud.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org3/tls-cert.pem
  set +x

  mkdir -p organizations/peerOrganizations/org3.cloud.com/users/Admin@org3.cloud.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://org3admin:org3adminpw@localhost:10054 --caname ca-org3 -M ${PWD}/organizations/peerOrganizations/org3.cloud.com/users/Admin@org3.cloud.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org3/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/org3.cloud.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org3.cloud.com/users/Admin@org3.cloud.com/msp/config.yaml

}

function createOrg4 {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/peerOrganizations/org4.cloud.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org4.cloud.com/
#  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
#  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:11054 --caname ca-org4 --tls.certfiles ${PWD}/organizations/fabric-ca/org4/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-org4.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-org4.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-org4.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-org4.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/org4.cloud.com/msp/config.yaml

  echo
	echo "Register peer0"
  echo
  set -x
	fabric-ca-client register --caname ca-org4 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/org4/tls-cert.pem
  set +x

  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-org4 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/org4/tls-cert.pem
  set +x

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-org4 --id.name org4admin --id.secret org4adminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/org4/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/org4.cloud.com/peers
  mkdir -p organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com

  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:11054 --caname ca-org4 -M ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/msp --csr.hosts peer0.org4.cloud.com --tls.certfiles ${PWD}/organizations/fabric-ca/org4/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/org4.cloud.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:11054 --caname ca-org4 -M ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/tls --enrollment.profile tls --csr.hosts peer0.org4.cloud.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/org4/tls-cert.pem
  set +x


  cp ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/org4.cloud.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org4.cloud.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/org4.cloud.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/org4.cloud.com/tlsca/tlsca.org4.cloud.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/org4.cloud.com/ca
  cp ${PWD}/organizations/peerOrganizations/org4.cloud.com/peers/peer0.org4.cloud.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/org4.cloud.com/ca/ca.org4.cloud.com-cert.pem

  mkdir -p organizations/peerOrganizations/org4.cloud.com/users
  mkdir -p organizations/peerOrganizations/org4.cloud.com/users/User1@org4.cloud.com

  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:11054 --caname ca-org4 -M ${PWD}/organizations/peerOrganizations/org4.cloud.com/users/User1@org4.cloud.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org4/tls-cert.pem
  set +x

  mkdir -p organizations/peerOrganizations/org4.cloud.com/users/Admin@org4.cloud.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://org4admin:org4adminpw@localhost:11054 --caname ca-org4 -M ${PWD}/organizations/peerOrganizations/org4.cloud.com/users/Admin@org4.cloud.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/org4/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/org4.cloud.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/org4.cloud.com/users/Admin@org4.cloud.com/msp/config.yaml

}