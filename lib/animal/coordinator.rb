
# The coordinator is the main instance which coordinates
# processing of log files.
module Animal

  class Coordinator

    YES = Class.new do
      def first(iap, line, ts) :yes end
      def initial(iap, line, ts) :yes end
      def followup(iap, line) :yes end
    end.new

    attr_reader :options, :filter, :files
    attr_accessor :parser

    def initialize
      @filter = YES
      @processors = LRUHash.new 50_000
      @processors.release_proc = Proc.new {|id, pro| pro.finish}

      @files = LRUHash.new 250 do |h, file_name|
        h[file_name] = File.open(file_name, 'a')
      end

      @files.release_proc = Proc.new {|fn, io| io.close}
    end

    def options=(opts)
      @options = opts

      # set filter from options
      @filter = YES

      # set LRU size limits from options
      @processors.max_size = @options.max_size if @options.max_size
      @files.max_size = @options.max_fd if @options.max_fd
    end

    def process_file(file)
      if file == '-'
        process_impl(file, $stdin)
      else
        File.open(file, IO::RDONLY) do |io|
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

    # Release all resources
    def finish
      @processors.clear
      @files.clear
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
          id = parser.interaction_id
          last_proc = @processors[id]

          unless last_proc
            # the first line of this interaction
            last_proc = InteractionProcessor.new(id.freeze, self)
            @processors[id] = last_proc
            last_proc.process_initial(parser.time_stamp, line)
          else
            # not the first line
            last_proc.process(parser.time_stamp, line)
          end

        else
          last_proc.append_line line
        end
      end
    end
  end

end
