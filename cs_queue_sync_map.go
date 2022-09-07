// based on https://gist.github.com/mattn/c68a326557cc9c3fd26190029dfbe73d

package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"sync"
)

var (
	ws = sync.Map{}
)

func Writer(conn net.Conn, w_in chan string) {
	for {
		msg, ok := <-w_in
		if !ok {
			break
		}
		fmt.Fprintln(conn, msg)
	}
}

func Reader(conn net.Conn, w_in chan string) {
	defer conn.Close()

	scanner := bufio.NewScanner(conn)

	for scanner.Scan() {
		text := scanner.Text()

		ws.Range(func(key any, val any) bool {
			w_out := key.(chan string)
			select {
			case w_out <- text:
			default:
				// drop this text
			}
			return true
		})
	}

	ws.Delete(w_in)
}

func main() {
	lis, err := net.Listen("tcp", ":12345")
	if err != nil {
		log.Fatal(err)
	}

	for {
		conn, err := lis.Accept()
		if err != nil {
			log.Print(err)
			break
		}
		fmt.Fprintln(conn, "connected")

		w_in := make(chan string, 100)
		ws.Store(w_in, 0)
		go Writer(conn, w_in)
		go Reader(conn, w_in)
	}
}
