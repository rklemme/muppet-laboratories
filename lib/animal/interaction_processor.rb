
require 'time'
require 'fileutils'

# An interaction processor is responsible for processing
# all log entries of a single interaction
module Animal

  # An entry in the list of log records
  Entry = Struct.new :time_stamp, :line

  # processor of a single interaction from the log
  class InteractionProcessor

    attr_reader :id, :coord, :entries

    def initialize(id, coordinator)
      @id = id
      @coord = coordinator
      @entries = []
    end

    # Process an initial line
    def process(time_stamp, line)
      # unfiltered for now
      @entries << Entry.new(time_stamp, line)
    end

    # Append a continuation line to the last entry
    def append_line(line)
      l = @entries.last and l.line << line
    end

    def finish
      # write out to file...
      unless @entries.empty? 
	fn = file_name
	FileUtils.mkdir_p(File.dirname(fn))
	File.open(fn, "w") do |io|
	  io.puts @entries.map(&:line)
	end
      end
    end

    private

    # calculate the file name, this fails if
    # there are no entries!
    def file_name
      ts = @entries.first.time_stamp
      File.join(@coord.options.output_dir,
		ts.strftime('%Y-%m-%d'),
		ts.strftime('%H-%M'),
		ts.strftime('%S.%3N-') + id)
    end
  end
end
