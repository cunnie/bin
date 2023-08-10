package main

import (
	"fmt"
	"log"
	"net/http"
	"strconv"
)

func handler(w http.ResponseWriter, r *http.Request) {
	// if r.URL.Path[1:]
	statusCode, err := strconv.Atoi(r.URL.Path[1:])
	if err != nil {
		fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
	}
	w.WriteHeader(statusCode)
}

func main() {
	http.HandleFunc("/", handler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
