#!/usr/local/bin/ruby19 -w

# create a sample log file to stdout

require 'optparse'

#
# types
#

TIME_FMT = '%Y-%m-%d %H:%M:%S.%3N'.freeze
DEFAULT_DURATION = 60 # 1 hour

MESSAGES = [
  'GET',
  'SET',
  <<EOS
java.io.FileNotFoundException: fred.txt
        at java.io.FileInputStream.<init>(FileInputStream.java)
        at java.io.FileInputStream.<init>(FileInputStream.java)
        at ExTest.readMyFile(ExTest.java:19)
        at ExTest.main(ExTest.java:7)
EOS
]

def normalize(n)
  n = n.to_i
  n - n % 60
end

def generate_id(len = 15)
  s = ''
  len.times { s << 97 + rand(26) }
  s.freeze
end

Timer = Struct.new :t do
  def tic
    self.t += rand(10_000) / 1000.0
  end
end

# a log entry
Entry = Struct.new :time, :line do
  def self.create(time, id, message)
    t = case time
        when Time then time
        when Integer, Float then Time.at(time)
        else Time.at(time.to_f)
        end
    new(time, "#{t.strftime(TIME_FMT)} #{id} #{message}")
  end

  def key; normalize(time); end
  def to_s; line; end
end

#
# argument processing
#

start_time = normalize(Time.now)
end_time = nil
duration = nil
commands = 1000

OptionParser.new do |opts|

  opts.on_tail '-h', '--help' do
    puts opts
    exit 0
  end

  opts.on '-s', '--start [TIME]', 'Starting time (defaults to now)' do |v|
    start_time = normalize(Time.parse(v))
  end

  opts.on '-e', '--end [TIME]', 'Ending time' do |v|
    end_time = normalize(Time.parse(v))
  end

  opts.on '-d', '--duration [MINUTES]', Integer, "Duration (default: #{DEFAULT_DURATION})" do |v|
    abort "ERROR: illegal duration: #{v}" if v <= 0
    duration = v
  end

  opts.on '-n', '--new [COMMANDS]', Integer,
    "Amount of new interactions per minute (default: #{commands})" do |v|
    abort "ERROR: illegal commands: #{v}" if v <= 0
    commands = v
    end

end.parse! ARGV

abort "ERROR: both duration and end time specified" if end_time && duration

end_time ||= start_time + (duration || DEFAULT_DURATION) * 60

# MAIN

entries = Hash.new {|h,minute| h[minute] = []}

class <<entries
  def add(e)
    self[e.key] << e
  end

  def print(k)
    pr = delete(k) and puts pr.sort_by {|e| e.time}
  end
end

t = start_time
tx = Timer.new t

while t < end_time
  # create new entries
  commands.times do
    id = generate_id
    tx.t = t + rand(60_000) / 1000.0

    entries.add(Entry.create(tx.t, id, 'START'))

    (2 + rand(8)).times do
      pick = rand(10)
      msg = pick == 0 ? MESSAGES.last : MESSAGES[pick % 2]
      entries.add(Entry.create(tx.tic, id, msg))
    end

    entries.add(Entry.create(tx.tic, id, 'END'))
  end

  # write entries of this minute
  entries.print t
  t += 60
end

# require 'pp'
# pp entries

# print remaining entries
entries.keys.sort.each do |k|
  entries.print k
end

$stderr.puts "WARNING: left overs" unless entries.empty?

# eof

