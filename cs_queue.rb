p File.basename(__FILE__)

require 'socket'

Socket::SOMAXCONN = 200000
p 'Socket::SOMAXCONN' => Socket::SOMAXCONN

# $VERBOSE = true

$m = Mutex.new
$writers = Set.new

def broadcast line
  $m.synchronize{
    $writers.each{|wq|
      wq.push line
    }
  }
end

trap(:INT){
  p gc_time: GC.stat(:time)
  exit
}

Thread.new{
  loop{
    p :monitor
    p thread_monitor: Thread.list.size
    sleep 20
  }
} if false

n = 0
rm1 = rm2 = 0

Socket.tcp_server_loop(12345){|sock, addr|
  p accept: [addr, sock] if $VERBOSE

  wq = Queue.new
  $m.synchronize{
    n += 1
    $writers << wq
  }

  Thread.new n do |ti|
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

  Thread.new n do |ti|
    sock.puts 'connected'

    while line = sock.gets
      broadcast line
    end
  rescue Errno::ECONNRESET, Errno::ETIMEDOUT
  ensure
    p closed: sock if $VERBOSE
    sock.close
    wq.close

    $m.synchronize{
      $writers.delete wq
    }

    # p [n, rm1, (rm2 += 1)]
  end
}

