package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"path/filepath"
	"strings"
)

func greetHandler(w http.ResponseWriter, r *http.Request) {
	sub := strings.TrimPrefix(r.URL.Path, "/hello")
	_, name := filepath.Split(sub)
	var m any
	if name != "" {
		m = map[string]interface{}{
			"message": fmt.Sprintf("Hello, %s!", name),
		}
	} else {
		m = map[string]interface{}{
			"status": 404,
		}
	}

	resJson, err := json.Marshal(m)
	if err != nil {
		panic(err.Error())
	}

	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, "%s", string(resJson))
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/hello/", greetHandler)

	http.ListenAndServe(":8080", mux)
}
