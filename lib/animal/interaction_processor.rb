
require 'time'
require 'fileutils'

# An interaction processor is responsible for processing
# all log entries of a single interaction
module Animal

  # An entry in the list of log records
  Entry = Struct.new :time_stamp, :line

  # processor of a single interaction from the log
  class InteractionProcessor

    UNDECIDED = Class.new do
      def process_initial(iap, line, time_stamp)
        case iap.coord.filter.first(iap, line, time_stamp)
        when :yes
          iap.entries << Entry.new(time_stamp, line)
          iap.io_open
          INCLUDE
        when :no
          iap.entries.clear
          EXCLUDE
        when :maybe
          iap.entries << Entry.new(time_stamp, line)
          self
        else
          raise 'Illegal return'
        end
      end

      def process(iap, line, time_stamp)
        case iap.coord.filter.initial(iap, line, time_stamp)
        when :yes
          iap.entries << Entry.new(time_stamp, line)
          iap.io_open
          INCLUDE
        when :no
          iap.entries.clear
          EXCLUDE
        when :maybe
          iap.entries << Entry.new(time_stamp, line)
          self
        else
          raise 'Illegal return'
        end
      end

      def append_line(iap, line)
        case iap.coord.filter.followup(iap, line)
        when :yes
          iap.io_open.puts line
          INCLUDE
        when :no
          iap.entries.clear
          EXCLUDE
        when :maybe
          l = iap.entries.last and l.line << line
          self
        else
          raise 'Illegal return'
        end
      end
    end.new

    INCLUDE = Class.new do
      def process_initial(iap, line, time_stamp)
        iap.io_get.puts line
        self
      end

      def process(iap, line, time_stamp)
        iap.io_get.puts line
        self
      end

      def append_line(iap, line)
        iap.io_get.puts line
        self
      end
    end.new

    EXCLUDE = Class.new do
      def process_initial(iap, line, ts)
        self
      end

      def process(iap, line, ts)
        self
      end

      def append_line(iap, line)
        self
      end
    end.new

    attr_reader :id, :coord, :entries

    def initialize(id, coordinator)
      @id = id
      @coord = coordinator
      @entries = []
      @state = UNDECIDED
    end

    # Process the first line
    def process_initial(time_stamp, line)
      @state = @state.process_initial(self, line, time_stamp)
    end

    # Process an initial line
    def process(time_stamp, line)
      @state = @state.process(self, line, time_stamp)
    end

    # Append a continuation line to the last entry
    def append_line(line)
      @state = @state.append_line(self, line)
    end

    def io_open
      fn = file_name
      FileUtils.mkdir_p(File.dirname(fn))
      # overwrite the first time:
      @io = @coord.files[file_name] = File.open(fn, "w")
      @io.puts(@entries.map(&:line))
      @entries = nil
      @io      
    end

    def io_get
      @io = @coord.files[file_name] if @io.closed?
      @io
    end

    def finish
      unless @io && @io.closed?
        @coord.files.delete(file_name)
      end
    end

    private

    # calculate the file name, this fails if
    # there are no entries!
    def file_name
      @ts ||= @entries.first.time_stamp
      File.join(@coord.options.output_dir,
                @ts.strftime('%Y-%m-%d'),
                @ts.strftime('%H-%M'),
                @ts.strftime('%S.%3N-') + id)
    end
  end
end

