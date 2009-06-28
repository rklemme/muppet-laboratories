#!/usr/local/bin/ruby19 -w

# Implementation of the parser for the sample
# generator script test-gen.rb.
$: << File.join(File.dirname(File.dirname($0)), "lib")

require 'animal'

# main defines the custom parser class!
Animal.main do

  attr_accessor :year
  attr_reader :interaction_id, :time_stamp

  def parse(line)
    if %r{
       ^
       ( \d{4} ) - ( \d{2} ) - ( \d{2} ) 
       \s
       ( \d{2} ) : ( \d{2} ) : ( \d{2}(?:\.\d+)? )
       \s+
       (\S+) # interaction_id
       \s+
       }x =~ line
      @time_stamp = Time.local $1.to_i, $2.to_i, $3.to_i,
	$4.to_i, $5.to_i, $6.to_f
      @interaction_id = $7
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
