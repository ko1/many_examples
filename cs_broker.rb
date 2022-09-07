p File.basename(__FILE__)

require 'socket'
# $VERBOSE = true
Socket::SOMAXCONN = 200000
p 'Socket::SOMAXCONN' => Socket::SOMAXCONN

# $VERBOSE = true

Thread.new{
  loop{
    p :monitor
    p thread_monitor: Thread.list.size
    sleep 2
  }
} if false

n = 0
rm1 = rm2 = 0

bq = Queue.new
ws = Hash.new

Thread.new do
  while cmd = bq.pop
    type, arg = *cmd
    case type
    when :add
      ws[arg] = true
    when :del
      ws.delete(arg)
      arg.close
    when :post
      ws.each_key do |wq|
        wq << arg
      end
    end
  end
end

Socket.tcp_server_loop(12345){|sock, addr|
  p accept: [addr, sock] if $VERBOSE
  wq = Queue.new

  _writer = Thread.new n do |ti|
    while line = wq.pop
      p [:writer, sock, line] if $VERBOSE

      begin
        sock.puts line
      rescue IOError, Errno::ECONNRESET
      end
    end
  ensure
    # p [n, (rm1 += 1), rm2]
  end

  bq << [:add, wq]

  _reader = Thread.new n do |ti|
    sock.puts 'connected'

    while line = sock.gets
      bq << [:post, line]
    end
  rescue Errno::ECONNRESET, Errno::ETIMEDOUT
  ensure
    p closed: sock if $VERBOSE
    sock.close
    bq << [:del, wq]
    # p [n, rm1, (rm2 += 1)]
  end
}

