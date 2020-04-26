package main

import (
	"fmt"
	"net/http"
	"log"
	"github.com/gorilla/mux"
	"strconv"
	"os"
	"github.com/go-redis/redis"
	"encoding/json"
	"net"
)

var redisClientMaster *redis.Client
var redisClientSlave *redis.Client
var logstashUrl string

type Operation struct {
	Number1    float64 `json:"number1"`
	Number2    float64 `json:"number2"`
	Type       string  `json:"type"`
	Result     float64 `json:"result"`
}

func redisConnectionMaster(redisMasterUrl string, redisMasterPass string) *redis.Client{
	client := redis.NewClient(&redis.Options{
		Addr: redisMasterUrl + ":6379",
		Password: redisMasterPass,
		DB: 0,
	})
	verifyIdOperation, _ := client.Do("exists", "idOperation").Int()
	if verifyIdOperation == 0 {
		client.Do("SET", "idOperation", 0)
	}
	return client
}

func redisConnectionSlave(redisSlaveUrl string, redisSlavePass string) *redis.Client{
	client := redis.NewClient(&redis.Options{
		Addr: redisSlaveUrl + ":6379",
		Password: redisSlavePass,
		DB: 0,
	})
	return client
}

func keyController() (int){
	idOperation, err := redisClientSlave.Do("GET", "idOperation").Int()
	if err != nil {
		logsOperations("errRedis")
	}
	return idOperation
}

func addOperation(number1 float64, number2 float64, typeOperation string, result float64) ([]byte){
	newData := Operation{
		Number1: number1,
		Number2: number2,
		Type: typeOperation,
		Result: result,
	}
	jsonOperation, _ := json.Marshal(newData)

	redisClientMaster.Do("SET", strconv.Itoa(keyController()) + ":" + newData.Type + ":" + strconv.FormatFloat(newData.Result, 'f', 2, 64), jsonOperation)
	redisClientMaster.Do("incr", "idOperation")
	return jsonOperation
}

func logsOperations(logType string){
	logOperation := log.New(os.Stdout, "", log.Ldate|log.Lmicroseconds|log.Lshortfile)
	logOperation.Print(logType)
	conn, _ := net.Dial("tcp", logstashUrl + ":5401")
	fmt.Fprintf(conn, logType + "\n")
}

func sum(response http.ResponseWriter, request *http.Request) {
	params := mux.Vars(request)
	number1, err := strconv.ParseFloat(params["num1"], 64);
	if err != nil {
		fmt.Fprint(response, err)
	}
	number2, err := strconv.ParseFloat(params["num2"], 64);
	if err != nil {
		fmt.Fprint(response, err)
	}
	result := number1 + number2
	jsonOperation := addOperation(number1, number2, "SUM", result)
	logsOperations("SUM")
	fmt.Fprint(response, string(jsonOperation))
}

func sub(response http.ResponseWriter, request *http.Request) {
	params := mux.Vars(request)
	number1, err := strconv.ParseFloat(params["num1"], 64);
	if err != nil {
		fmt.Fprint(response, err)
	}
	number2, err := strconv.ParseFloat(params["num2"], 64);
	if err != nil {
		fmt.Fprint(response, err)
	}
	result := number1 - number2
	jsonOperation := addOperation(number1, number2, "SUB", result)
	logsOperations("SUB")
	fmt.Fprint(response, string(jsonOperation))
}

func div(response http.ResponseWriter, request *http.Request) {
	params := mux.Vars(request)
	number1, err := strconv.ParseFloat(params["num1"], 64);
	if err != nil {
		fmt.Fprint(response, err)
	}
	number2, err := strconv.ParseFloat(params["num2"], 64);
	if err != nil {
		fmt.Fprint(response, err)
	}
	if number2 == 0 {
		logsOperations("Div Operation for 0!")
	} else {
		result := number1 / number2
		jsonOperation := addOperation(number1, number2, "DIV", result)
		logsOperations("DIV")
		fmt.Fprint(response, string(jsonOperation))
	}
}

func mul(response http.ResponseWriter, request *http.Request) {
	params := mux.Vars(request)
	number1, err := strconv.ParseFloat(params["num1"], 64);
	if err != nil {
		fmt.Fprint(response, err)
	}
	number2, err := strconv.ParseFloat(params["num2"], 64);
	if err != nil {
		fmt.Fprint(response, err)
	}
	result := number1 * number2
	jsonOperation := addOperation(number1, number2, "MUL", result)
	logsOperations("MUL")
	fmt.Fprint(response, string(jsonOperation))
}

func historic(response http.ResponseWriter, request *http.Request) {
	keys, err := redisClientSlave.Keys("*").Result()
	if err != nil {
		fmt.Fprint(response, err)
	}
	logsOperations("HISTORY")
	for _, key := range keys {
		if key != "idOperation" {
			operation, err2 := redisClientSlave.Get(key).Result()
			if err2 != nil {
				fmt.Fprint(response, err2)
			}
			fmt.Fprint(response, operation)
		}
	}
}

func main() {
	fmt.Println("Creating Redis connection...")
	redisClientMaster = redisConnectionMaster(os.Args[2], os.Args[4])
	redisClientSlave = redisConnectionSlave(os.Args[3], os.Args[5])
	logstashUrl = os.Args[1]
	fmt.Println("Calculator Script in Go!")
	fmt.Println("Serving at port 5000!")
	router := mux.NewRouter()
	api := router.PathPrefix("/calc").Subrouter()
	api.HandleFunc("/historic", historic).Methods("GET")
	api.HandleFunc("/sum/{num1}/{num2}", sum).Methods("POST")
	api.HandleFunc("/sub/{num1}/{num2}", sub).Methods("POST")
	api.HandleFunc("/div/{num1}/{num2}", div).Methods("POST")
	api.HandleFunc("/mul/{num1}/{num2}", mul).Methods("POST")
	log.Fatal(http.ListenAndServe(":5000", router))
}
