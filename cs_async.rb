#!/usr/bin/env ruby

p File.basename(__FILE__)

require 'socket'
require 'async'
require 'async/io/host_endpoint'
require 'io/nonblock'

Async do |task|
  endpoint = Async::IO::Endpoint.tcp('0.0.0.0', 12345)

  peers = {}
  
  task.async do
    while true
      sleep 1
      p peers: peers.size
    end
  end

  endpoint.accept do |socket|
    socket = socket.to_io
    socket.puts('connected')

    peers[socket] = true
    begin
      while line = socket.gets
        $stderr.write "."
        peers.each_key do |peer|
          peer.puts line
        end
      end
    rescue Errno::ECONNRESET
      # Ignore.
    ensure
      peers.delete(socket)
      socket.close
    end
  end
end
