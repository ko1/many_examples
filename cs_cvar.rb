p File.basename(__FILE__)

require 'socket'

# $VERBOSE = true

$m = Mutex.new
$cv = Thread::ConditionVariable.new
$ary = []

def broadcast line, tid:
  $m.synchronize do
    p tid: tid, line: line if $VERBOSE

    $ary << line
    $cv.broadcast
  end
end

def receive sock, from = $ary.size, tid:
  until sock.closed?
    to = $ary.size

    if from < to
      a = $ary[from ... to]
      p tid:tid, a:a if $VERBOSE
      a.each{|line| yield line}
      from = to
    end

    $m.synchronize do
      if !(from < to) && !sock.closed?
        $cv.wait($m)
      end
    end
  end
end

Thread.new{
  loop{
    p thread_monitor: Thread.list.size
    sleep 3
  }
} if false

n = 0
Socket.tcp_server_loop(12345){|sock, addr|
  p accept: [addr, sock] if $VERBOSE
  n += 1

  # writer
  Thread.new n do |n|
    receive sock, tid: n do |line|
      sock.puts line
    end
  end

  # reader
  Thread.new n do |n|
    sock.puts 'connected'

    while line = sock.gets
      broadcast line, tid: n
    end
  rescue Errno::ECONNRESET
  ensure
    p closed: sock if $VERBOSE

    $m.synchronize{
      sock.close
      $cv.broadcast
    }
  end
}
