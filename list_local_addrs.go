package main

import (
	"fmt"
	"net"
)

func main() {
	var ifaces []net.Interface
	var err error
	if ifaces, err = net.Interfaces(); err != nil {
		panic(err)
	}
	for _, i := range ifaces {
		var addrs []net.Addr
		if addrs, err = i.Addrs(); err != nil {
			panic(err)
		}
		//fmt.Println("interface: " + i.Name) // lo0, en0, etc...
		for _, addr := range addrs {
			fmt.Println(addr.String())
		}
	}
}
