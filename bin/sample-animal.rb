#!/usr/local/bin/ruby19 -w

# Implementation of the parser for the sample
# generator script test-gen.rb.
$: << File.join(File.dirname(File.dirname($0)), "lib")

require 'time'
require 'animal'

# main defines the custom parser class!
Animal.main do

  TIME_FORMAT = '%Y-%m-%d %H:%M:%S.%N'.freeze

  attr_accessor :year
  attr_reader :interaction_id, :time_stamp

  def parse(line)
    if %r{
       ^
       ( \d{4}-\d{2}-\d{2} \s \d{2}:\d{2}:\d{2}(?:\.\d+)? )
       \s+
       (\S+) # interaction_id
       \s+
       }x =~ line
      @time_stamp = Time.strptime $1, TIME_FORMAT
      @interaction_id = $2
    else
      @time_stamp = nil
      @interaction_id = nil
    end
  end

  def initial_line?
    time_stamp
  end
end

# EOF
