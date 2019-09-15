package main

import (
	"fmt"
	"net"
)

// main binds to a port and sends back the Remote Address and the local address
// FIXME: I don't think this works
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
		_, err = conn.Write([]byte(fmt.Sprintf("%s\n%s\n", conn.RemoteAddr(), ln.Addr())))
		err = conn.Close()
		if err != nil {
			panic("Oh dear, I couldn't Close()")
		}

	}
}
