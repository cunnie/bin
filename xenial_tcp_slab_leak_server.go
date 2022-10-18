package main

/*

	This program helps expose a TCP slab leak in an ESM Xenial kernel
	- run this program on any server (in this case morgoth.nono.io)
	- on Xenial, run the following command:
		sudo iptables -I OUTPUT -p tcp --dst morgoth.nono.io -j NFQUEUE --queue-num=1 --queue-bypass
	- on Xenial, compile and run the xenial_tcp_slab_nfnetlink.go
		go build xenial_tcp_slab_nfnetlink.go
		sudo ./xenial_tcp_slab_nfnetlink
	- on Xenial, in another window, run the following
		sudo slabtop --sort c
	- on Xenial, in another window, run the following
		while true; do echo "" | netcat morgoth.nono.io 8080; done

*/
import (
	"bufio"
	"log"
	"net"
)

func main() {
	addr := ":8080"
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		log.Fatal(err)
	}
	for {
		conn, _ := ln.Accept()
		go func() {
			_, _ = bufio.NewReader(conn).ReadString('\n')
			conn.Write([]byte("."))
			conn.Close()
		}()
	}
}
