
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
          # we'll improve this once LRU is there
          iap.entries << Entry.new(time_stamp, line)
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
          # we'll improve this once LRU is there
          iap.entries << Entry.new(time_stamp, line)
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
          # we'll improve this once LRU is there
          l = iap.entries.last and l.line << line
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
        iap.entries << Entry.new(time_stamp, line)
        self
      end

      def process(iap, line, time_stamp)
        iap.entries << Entry.new(time_stamp, line)
        self
      end

      def append_line(iap, line)
        l = iap.entries.last and l.line << line
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
