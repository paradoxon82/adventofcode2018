#!/usr/bin/ruby

#require 'rspec/autorun'

class Polymer

  def initialize(initial_sequence)
    @verbose = false
    @initial_sequence = initial_sequence
  end

  # reacts if the two chars are the same but different case
  def reacts?(left, right)
    return false if left.nil? || right.nil?
    if left != right 
      # case insensitive compare
      left.casecmp(right) == 0
    else
      false
    end
  end

  # go back along the way of the sequence to the left and right of the starting point, to find out how the length will retract
  def retraction(remainder, sequence, starting_point)
    ret = 0
    puts "retraction, remainder is #{remainder}, starting_point #{starting_point}" if @verbose
    #compare the sequence from the starting_point with the remainder going backwards
    while reacts?(sequence[starting_point+ret], remainder[-(ret+1)])
      ret += 1
    end
    puts "retracting by #{ret} at #{starting_point}" if ret > 0 && @verbose
    remainder.pop(ret) 
    puts "remainder is #{remainder}" if ret > 0 && @verbose
    ret
  end

  def length_after_reaction
    length_after_reaction_of(@initial_sequence)
  end

  def length_after_reaction_of(sequence)
    return 0 if sequence.empty?

    remainder = []
    i = 0
    length = sequence.size
    while i < length
      if reacts?(sequence[i], sequence[i+1])
        retracted = retraction(remainder, sequence, i + 2)
        i += retracted
        i += 1
      else
        remainder << sequence[i]
      end
      i += 1
    end
    remainder.size
  end

end

class Reactor
  attr_reader :sequence_string, :uniqe_units

  def initialize()
    @sequence_string = ''
  end

  def add_line(line)
    @sequence_string.concat(line)
  end

  def length_after_reaction
    Polymer.new(@sequence_string.chars).length_after_reaction
  end

  def shortest_length_after_reaction
    sequence = @sequence_string.chars
    @uniqe_units = sequence.uniq.map(&:upcase).uniq

    @result_sizes = {}
    @uniqe_units.each do |unit|
      puts "unit: #{unit}"
      fixed_sequence = sequence - [unit, unit.downcase]
      puts "fixed_sequence size: #{fixed_sequence.size}"
      result = Polymer.new(fixed_sequence).length_after_reaction
      @result_sizes[unit] = result
      puts "result size: #{result}"
    end

    unit, size = @result_sizes.min_by {|unit, size| size }
    puts "shortest without unit #{unit}"
    size
  end

end

# RSpec.describe Polymer do
#   let(:input) {
#     'dabAcCaCBAcCcaDA'
#   }

#   describe '#square_overlap_count' do
#     it 'calculates the example' do
#       expect(Claims.new(input).square_overlap_count).to eq(4)
#     end
#   end

#   describe '#non_overlapping_claims' do
#     it 'returns the non-overlapping squares' do
#       expect(Claims.new(input).non_overlapping_claims.map(&:id)).to eq(['3'])
#     end
#   end
# end

reactor = Reactor.new
test_sequence = 'dabAcCaCBAcCcaDA'
reactor.add_line(test_sequence)
puts "test sequence: #{test_sequence}"
puts "result size: #{reactor.length_after_reaction}"

reactor = Reactor.new
File.open(ARGV[0]).each_line do |line|
  reactor.add_line(line.strip)
end
puts "result size: #{reactor.length_after_reaction}"
puts "shortest length: #{reactor.shortest_length_after_reaction}"

# 'dabCBAcaDA'

# puts "shortest result: #{reactor.shortest_length_after_reaction}"

# reactor = Reactor.new
# reactor.add_line('dabAcCaCBAcCcaDA')
# puts "input: #{reactor.sequence_string}, result: #{reactor.result_string}" 
# puts "matches: #{reactor.result_string == 'dabCBAcaDA'}"

# RSpec.describe Reactor do
#   describe '#result' do
#     it 'returns the resulting polymer' do
#       result = 'dabCBAcaDA'

#       expect(Polymer.new('dabAcCaCBAcCcaDA').result == result)
#     end
#   end
# end