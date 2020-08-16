package main

import (
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"encoding/json"
	"fmt"
	"strconv"
	"os"
	"io"
	"strings"
	"encoding/base64"
	"path/filepath"
	"crypto/sha256"
	"time"
	"context"
	"cloud.google.com/go/storage"
	"google.golang.org/api/option"
)

type SmartContract struct {
	contractapi.Contract
}

type Data struct {
	Owner 			string `json:"owner"`
	File 			string `json:"file"`
	FileChunkNumber string `json:"filechunknumber"`
	SHA256 			string `json:"sha256"`
}

func uploadGCS(owner, filechunklocation, uploadlocation string) error {
	ct := context.Background()	
	client, err := storage.NewClient(ct, option.WithCredentialsFile("/home/service_account.json"))
	if err != nil {
		return fmt.Errorf("storage.NewClient: %v", err)
	}
	defer client.Close()
	// Open local file.
	f, err := os.Open(filechunklocation)
	if err != nil {
		return fmt.Errorf("os.Open: %v", err)
	}
	defer f.Close()

	ct, cancel := context.WithTimeout(ct, time.Second*50)
	defer cancel()
	
	// Upload an object with storage.Writer.
	wc := client.Bucket("btp2016bcs0015-cloud-storage").Object(uploadlocation).NewWriter(ct)
	if _, err = io.Copy(wc, f); err != nil {
		return fmt.Errorf("io.Copy: %v", err)
	}
	if err := wc.Close(); err != nil {
		return fmt.Errorf("Writer.Close: %v", err)
	}
	return nil
}

func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	filelocation := "/home/abc___jpg"
	data := []Data{
		Data{Owner: "ID126859", File: "abc.jpg", FileChunkNumber: "1", SHA256: "2ee6ca1353bd9326d40962481745b41f82fa9c8a2c5b703d28c6a8afb9cd661e"},
		Data{Owner: "ID126859", File: "abc.jpg", FileChunkNumber: "3", SHA256: "6c5b2dede3122e1120e6dd034c076273958811ef53773fc9ab6f72a0e5e11f5a"},
		Data{Owner: "ID126859", File: "abc.jpg", FileChunkNumber: "5", SHA256: "3946945d8310175a999c56d6bcc9eccbbb91d8a3d584815c27fb386c17b4ace2"},
		Data{Owner: "ID126859", File: "abc.jpg", FileChunkNumber: "2", SHA256: "07ec7e71af136b7a143bb2e363abd0d5724b030085aca64fde156f645279796f"},
		Data{Owner: "ID126859", File: "abc.jpg", FileChunkNumber: "4", SHA256: "d6c50c7364aab69bf96b37bd8c83d71a39ad18c7fcedd167e68d722d9489ca7e"},
		Data{Owner: "ID126859", File: "abc.jpg", FileChunkNumber: "6", SHA256: "4ec7419abcaf19ee5f4bacdd0935d6ac3d6ad56cff04d55e602aced4f64d339a"},
	}

	for i := range data {
		_, dir := filepath.Split(filelocation)
		dir_1 := strings.Split(dir,"___")
		filechunk := dir_1[0]+"_"+ data[i].FileChunkNumber
		filechunklocation := filepath.Join(filelocation, filechunk)
		uploadlocation :=  data[i].Owner + "/" + dir + "/" + filechunk
		
		err := uploadGCS(data[i].Owner, filechunklocation, uploadlocation)
		
		if err != nil {
			return fmt.Errorf("Got an error %s", err.Error())
		}
	}

	for i, putdata := range data {
		dataAsBytes, _ := json.Marshal(putdata)
		err := ctx.GetStub().PutState("DATA"+strconv.Itoa(i), dataAsBytes)

		if err != nil {
			return fmt.Errorf("Failed to put to world state. %s", err.Error())
		}
	}

	return nil
}

// Uploads new data to the world state with given details
func (s *SmartContract) UploadData(ctx contractapi.TransactionContextInterface, dataID string, owner string, filelocation string, filechunknumber string) error {
	if dataID == "" {
		return nil
	}
	//Uploads the filechunk to the cloud storage
	_, dir := filepath.Split(filelocation)
	dir_1 := strings.Split(dir,"___")
	filechunk := dir_1[0]+"_"+ filechunknumber
	filechunklocation := filepath.Join(filelocation, filechunk)
	uploadlocation :=  owner + "/" + dir + "/" + filechunk
	err := uploadGCS(owner, filechunklocation, uploadlocation)
	if err != nil {
		fmt.Println(err.Error())
		return err
	}
	//Creates SHA256 hash of the file chunk
	f, err := os.Open(filechunklocation)
	if err != nil {
		fmt.Errorf("%s",err)
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		fmt.Errorf("%s",err)
	}
	data := Data{
		Owner: owner,
		File: dir_1[0]+"."+dir_1[1],
		FileChunkNumber: filechunknumber,
		SHA256: base64.StdEncoding.EncodeToString(h.Sum(nil)),
	}
	dataAsBytes, _ := json.Marshal(data)
	return ctx.GetStub().PutState(dataID, dataAsBytes)
}


// QueryData returns the data stored in the world state with given id
func (s *SmartContract) QueryData(ctx contractapi.TransactionContextInterface, dataID string) (*Data, error) {
	dataAsBytes, err := ctx.GetStub().GetState(dataID)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if dataAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", dataID)
	}

	data := new(Data)
	_ = json.Unmarshal(dataAsBytes, data)

	return data, nil
}


func main() {

	chaincode, err := contractapi.NewChaincode(new(SmartContract))

	if err != nil {
		fmt.Printf("Error create cloud chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting cloud chaincode: %s", err.Error())
	}
}