package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"runtime"
	"time"
)

type Cmd struct {
	cmd string
	msg string
	wq  chan string
}

func Monitor(ws map[chan string]int) {
	for {
		time.Sleep(time.Second * 10)
		fmt.Printf("gor: %d, ws: %d\n", runtime.NumGoroutine(), len(ws))
	}
}

func Broker(b_in chan Cmd) {
	ws := make(map[chan string]int)
	// go Monitor(ws)

	for {
		cmd, ok := <-b_in

		if !ok {
			break
		}

		// fmt.Printf("%#v\n", cmd)

		switch cmd.cmd {
		case "add":
			ws[cmd.wq] = 0
		case "del":
			close(cmd.wq)
			delete(ws, cmd.wq)
		case "put":
			for wq, _ := range ws {
				select {
				case wq <- cmd.msg:
				default:
					// drop this message
				}
			}
		default:
			panic("unkonwn command")
		}
	}
}

func Writer(conn net.Conn, w_in chan string) {
	for {
		msg, ok := <-w_in
		if !ok {
			break
		}
		fmt.Fprintln(conn, msg)
	}
}

func Reader(conn net.Conn, b_in chan Cmd, w_in chan string) {
	defer conn.Close()

	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		text := scanner.Text()
		cmd := Cmd{cmd: "put", msg: text}
		b_in <- cmd
	}

	b_in <- Cmd{cmd: "del", wq: w_in}
}

func main() {
	lis, err := net.Listen("tcp", ":12345")
	if err != nil {
		log.Fatal(err)
	}

	b_in := make(chan Cmd, 1000)
	go Broker(b_in)

	for {
		conn, err := lis.Accept()
		if err != nil {
			log.Print(err)
			break
		}
		fmt.Fprintln(conn, "connected")
		w_in := make(chan string, 100)
		cmd := Cmd{cmd: "add", wq: w_in}
		b_in <- cmd
		go Writer(conn, w_in)
		go Reader(conn, b_in, w_in)
	}
}
