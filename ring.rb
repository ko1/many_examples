# ring example
# GC.disable

class SW
  def initialize
    @lap = @start = Time.now
  end
  
  def lap_time
    t = Time.now
    r = t - @lap
    @lap = t
    r
  end
  
  def elapsed_time
    Time.now - @start
  end
end

def trial tn
  sw = SW.new
  
  next_q = Queue.new
  first_q = prev_q = Queue.new
  
  ts = tn.times.map do |i|
    t = Thread.new prev_q, next_q do |prev_q, next_q|
      while token = prev_q.pop
        # p [i, token]
        next_q << token
      end
      next_q.close
      # p closed: i
    end
    prev_q = next_q
    next_q = Queue.new
    t
  end
  
  setup_time = sw.lap_time
  
  first_q << :ok
  prev_q.pop
  
  loop_time1 = sw.lap_time
  
  first_q << :ok
  prev_q.pop
  
  loop_time2 = sw.lap_time
  
  first_q << :ok
  prev_q.pop
  
  loop_time3 = sw.lap_time
  
  1_000_000.times do
    first_q << :ok
    prev_q.pop
  end if false

  loop_time1M = sw.lap_time

  first_q.close
  ts.each(&:join)

  cleanup_time = sw.lap_time

  rs = [setup_time, loop_time1, loop_time2, loop_time3, 
    # loop_time1M, 
    cleanup_time]
  puts "#{tn}\t#{rs.join("\t")}"
  STDOUT.flush
end

trial ARGV.shift.to_i
GC.start
