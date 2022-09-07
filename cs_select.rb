p File.basename(__FILE__)

require 'socket'

n = 0

socks = []

wset = Hash.new{|h, k| h[k] = []} # sock => []

Socket.tcp_server_sockets(12345){|accept_socks|
  socks = accept_socks
  accept_socks_set = Set.new(accept_socks)

  while true
    # p [socks.size, wset.size]
    rs, ws = IO.select(socks, wset.keys)
    # pp [rs, ws]

    rs.each{|s|
      case s
      when accept_socks_set
        begin
          while true
            new_sock, addr_info = s.accept_nonblock
            new_sock.puts 'connected'
            socks << new_sock
          end
        rescue Errno::EAGAIN
        end
      else
        begin
          line = s.gets
        rescue Errno::ECONNRESET
          s.close
          socks.delete s
          next
        end

        if line
          socks[2..].each{|ws|
            wset[ws] << line # line has "\n" already
          }
        else
          s.close
          socks.delete s
        end
      end
    }

    ws.each{|s|
      while line = wset[s].shift
        begin
          # p [s, line]
          n = s.write_nonblock line
          if n == line.size
            # ok
          else
            wset[s].unshift line[n..]
            break
          end
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK, IOError
          wset.delete s
          break
        end
      end
      wset.delete s if wset[s].empty?
    }
  end
}
