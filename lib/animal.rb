
require 'ostruct'

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
