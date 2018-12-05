#!/usr/bin/ruby

#require 'rspec/autorun'

class Polymer

  def initialize(initial_sequence)
    @initial_sequence = initial_sequence.chars
  end

  # reacts if the two chars are the same but different case
  def reacts?(left, right)
    if left != right 
      left.upcase == right || left.downcase == right
    else
      false
    end
  end

  def react(sequence)
    remainder = []
    # at least one reaction was done
    found_one = false
    retrun false if sequence.empty?

    skip_one = false
    sequence.each_cons(2) do |left, right|
      if skip_one
        skip_one = false
        next
      end
      if reacts?(left, right)
        found_one = true
        skip_one = true
      else
        remainder << left 
      end
    end
    # skip_one is false if the last pair in the sequence did not match,
    # so we have to add the missing last char
    unless skip_one
      remainder << sequence.last
    end
    sequence.replace(remainder)

    found_one
  end

  def result
    sequence = @initial_sequence.clone
    while react(sequence)
    end
    sequence.join
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

  def result_string
    Polymer.new(@sequence_string).result
  end

  def shortest_result
    @uniqe_units = @sequence_string.upcase.chars.uniq
    @result_sizes = {}
    @uniqe_units.each do |unit|
      puts "unit: #{unit}"
      fixed_sequence = @sequence_string.delete([unit, unit.downcase].join)
      puts "fixed_sequence size: #{fixed_sequence.size}"
      result = Polymer.new(fixed_sequence).result
      @result_sizes[unit] = result.size
      puts "result size: #{result.size}"
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
File.open(ARGV[0]).each_line do |line|
  reactor.add_line(line.strip)
end
puts "result size: #{reactor.result_string.size}"
puts "shortest result: #{reactor.shortest_result}"

reactor = Reactor.new
reactor.add_line('dabAcCaCBAcCcaDA')
puts "input: #{reactor.sequence_string}, result: #{reactor.result_string}" 
puts "matches: #{reactor.result_string == 'dabCBAcaDA'}"

# RSpec.describe Reactor do
#   describe '#result' do
#     it 'returns the resulting polymer' do
#       result = 'dabCBAcaDA'

#       expect(Polymer.new('dabAcCaCBAcCcaDA').result == result)
#     end
#   end
# end