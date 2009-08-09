
require 'time'
require 'fileutils'

# An interaction processor is responsible for processing
# all log entries of a single interaction
module Animal

  # An entry in the list of log records
  Entry = Struct.new :time_stamp, :line

  # processor of a single interaction from the log
  class InteractionProcessor
    
    # mode for writing files
    OPEN_MODE = IO::WRONLY | IO::CREAT | IO::TRUNC

    attr_reader :id, :coord, :entries

    def initialize(id, coordinator)
      @id = id
      @coord = coordinator
      @entries = []
    end

    # Process the first line
    def process_initial(time_stamp, line)
      process(time_stamp, line)
    end

    # Process an initial line
    def process(time_stamp, line)
      @entries << Entry.new(time_stamp, line)
    end

    # Append a continuation line to the last entry
    def append_line(line)
      @entries.last.line << line
    end

    def finish
      if ! @entries.empty? && @coord.filter[self]
        fn = file_name
        FileUtils.mkdir_p(File.dirname(fn))

        File.open(fn, OPEN_MODE) do |io|
          @entries.each {|e| io.puts(e.line)}
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

