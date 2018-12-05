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
    retrun remainder if sequence.empty?

    skip_one = false
    sequence.each_cons(2) do |left, right|
      if skip_one
        skip_one = false
        next
      end
      if reacts?(left, right)
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
  end

  def result
    sequence = @initial_sequence.clone
    while react(sequence)
    end
    sequence.join
  end
end

class Reactor

  def initialize(sequence_string)
    @sequence_string = sequence_string
  end

  def result
    Polymer.new(@sequence_string).result
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

reactor = Reactor.new('dabAcCaCBAcCcaDA')
puts "input: #{reactor.sequence}, result: #{reactor.result}" 
puts "matches: #{reactor.result == 'dabCBAcaDA'}"

# RSpec.describe Reactor do
#   describe '#result' do
#     it 'returns the resulting polymer' do
#       result = 'dabCBAcaDA'

#       expect(Polymer.new('dabAcCaCBAcCcaDA').result == result)
#     end
#   end
# end