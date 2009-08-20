
require 'ostruct'
require 'optparse'
require 'optparse/time'

autoload 'LRUHash', 'lruhash'
autoload 'Set', 'set'

# Namespace for all the Animal related classes
# Animal is the project on Ruby Best Practices
# blog which demonstrates the thought process
# of writing an application
module Animal

  # Parse the given command line and return an option instance.
  # Options are removed from the argument so what is left in
  # there must be file names.
  def self.parse_command_line(argv = ::ARGV) 
    o = OpenStruct.new(:output_dir => ".")

    # parse
    OptionParser.new do |opts|
      opts.on '-d', '--dir=DIRECTORY', 'Output directory ' do |v|
        o.output_dir = v
      end

      opts.on '-r', '--rx=REGEXP', ::Regexp, 'Regular expression matched',
      'against log line text' do |v|
        o.rx = v
      end

      opts.on '-t', '--time=TIME', ::Time, 'timestamp' do |v|
        o.ts = v
      end

      opts.on '-s', '--start=TIME', ::Time, 'start timestamp' do |v|
        o.start_ts = v
      end

      opts.on '-e', '--end=TIME', ::Time, 'end timestamp' do |v|
        o.end_ts = v
      end

      opts.on '--ids=ID_LIST', ::Array, 'Comma separated list of interaction ids' do |v|
        (o.ids ||= Set.new).merge v
      end

      opts.on '--id-file=FILE', 'File with ids one per line',
       '(empty lines are ignored)' do |v|
        s = o.ids ||= Set.new

        File.foreach v do |line|
          line.strip!
          s << line unless line == ''
        end
       end

      opts.on '--buffer=INTERACTIONS', ::Integer,
        'Max no. of interactions to keep in memory' do |v|
        o.max_size = v
        end

      opts.on_tail '-h', '--help' do
        puts opts
        exit 0
      end
    end.parse! argv

    raise 'Only one of time or (start, end) allowed' if o.ts && (o.start_ts || o.end_ts)
    raise 'Missing end timestamp' if o.start_ts && !o.end_ts
    raise 'Missing start timestamp' if !o.start_ts && o.end_ts

    if o.ids && (o.ts || o.start_ts || o.end_ts)
      warn 'WARNING: Ignoring time filters with ids given' 
      o.ts = o.start_ts = o.end_ts = nil
    end

    o
  end

  # This metho allows to write extremely short applications
  # because it accepts a block which is used to define the
  # parser class.  Alternatively users can provide a parser
  # instance.  The default command line is added implicitly
  # and will be option parsed and the whole processing will
  # start automatically.
  def self.main(parser = nil, argv = ::ARGV, &class_body)
    $stderr.puts 'WARNING: ignoring class body' if parser && class_body
    parser ||= Class.new(&class_body).new
    options = parse_command_line(argv)
    coord = Coordinator.new
    coord.parser = parser
    coord.options = options
    coord.process_files argv
  end

  # autoload init
  %w{
    Coordinator
    ProcessingStorage
    FileStatistics
    InteractionProcessor
  }.each do |cl|
    autoload cl, "animal/#{cl.gsub(/([a-z])([A-Z])/, '\\1_\\2').downcase}"
  end

end
