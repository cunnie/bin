package main

import (
	"net"
)

func main() {
	ln, err := net.Listen("tcp", ":8080")
	if err != nil {
		// handle error
	}
	for {
		conn, err := ln.Accept()
		if err != nil {
			panic("Oh dear, I couldn't Accept()")
		}
		// go handleConnection(conn)
		_, err = conn.Write([]byte("vim-go\n"))
		err = conn.Close()
		if err != nil {
			panic("Oh dear, I couldn't Close()")
		}

	}
}
