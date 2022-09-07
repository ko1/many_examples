package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"sync"
)

var (
	db = make([]string, 10)
	mu sync.Mutex
	cv = sync.NewCond(&mu)
)

func Writer(conn net.Conn) {
	pos := len(db)
	var text string

	for {
		mu.Lock()
		{
			for {
				if len(db) > pos {
					text = db[pos]
					pos += 1
					break
				} else {
					cv.Wait()
				}
			}
		}
		mu.Unlock()
		fmt.Fprintln(conn, text)
	}
}

func Reader(conn net.Conn) {
	defer conn.Close()

	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		text := scanner.Text()

		mu.Lock()
		db = append(db, text)
		cv.Broadcast()
		mu.Unlock()
	}
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

		go Writer(conn)
		go Reader(conn)
	}
}
