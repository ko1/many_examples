N = ARGV.shift.to_i
Type = ARGV.shift.to_sym

require 'benchmark'

def make_threads n
  ts = nil
  q = Queue.new
  ct = Benchmark.measure do
    ts = n.times.map do |n|
      Thread.new do
        # wait for the wakeup
        q.pop
      end
    end
  end
  qt = Benchmark.measure do
    q.close
  end
  jt = Benchmark.measure do
    ts.each(&:join)
    ts = nil
    GC.start
  end

  ts = [ct.real, qt.real, jt.real]
  puts [n, ts.sum, *ts].join("\t")
end

def make_ractors n
  rs = nil
  pipe = Ractor.new{Ractor.receive}
  ct = Benchmark.measure do
    rs = n.times.map do |n|
      Ractor.new pipe do |pipe|
        # wait for the wakeup
        pipe.take
      rescue Ractor::ClosedError
        nil
      end
    end
  end
  qt = Benchmark.measure do
    pipe << :close
  end
  jt = Benchmark.measure do
    rs.each(&:take)
    rs = nil
    GC.start
  end

  ts = [ct.real, qt.real, jt.real]
  puts [n, ts.sum, *ts].join("\t")
end

GC.disable

case Type
when :thread
  make_threads N
when :ractor
  make_ractors N
else 
  raise "Unknown: #{Type.inspect}"
end

