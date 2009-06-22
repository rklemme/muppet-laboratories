
# The coordinator is the main instance which coordinates
# processing of log files.
module Animal
  class Coordinator

    YES = lambda {|processor| true}

    attr_reader :options
    attr_accessor :parser

    def initialize
      @filter = YES
      @processors = Hash.new do |h, id|
	id.freeze
	h[id] = InteractionProcessor.new(id, self)
      end
    end

    def options=(opts)
      @options = opts

      # set filter from options
      @filter = YES
    end

    def process_file(file)
      if file == '-'
	process_impl(file, $stdin)
      else
	File.open(file, "r") do |io|
	  process_impl(file, io)
	end
      end
    end

    def process_files(files = ::ARGV)
      files.each do |f|
	process_file(f)
      end
      finish
      self
    end

    # Trigger finish processing after a set of
    # files has been processed.
    def finish
      @processors.each do |id, pr|
	pr.finish
      end
      self
    end

    private

    # Determine the year of the given log file
    # in case timestamps do not have a year.
    def determine_year(file, io)
      # fallback
      Time.now.year
    end

    def process_impl(name, io)
      parser.year = determine_year(name, io)
      last_proc = nil

      io.each do |line|
	parser.parse line

	if parser.initial_line?
	  last_proc = @processors[parser.interaction_id]
	  last_proc.process(parser.time_stamp, line)
	else
	  last_proc.append_line line
	end
      end
    end
  end
end
