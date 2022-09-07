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
	ws = make(map[chan string]int)
	mu sync.Mutex
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

func Reader(conn net.Conn, w chan string) {
	defer conn.Close()

	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		text := scanner.Text()

		mu.Lock()
		for w_in, _ := range ws {
			select {
			case w_in <- text:
			default:
				// drop this text
			}
		}
		mu.Unlock()
	}

	mu.Lock()
	delete(ws, w)
	mu.Unlock()
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
		mu.Lock()
		{
			ws[w_in] = 0
		}
		mu.Unlock()

		go Writer(conn, w_in)
		go Reader(conn, w_in)
	}
}
