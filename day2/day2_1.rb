#!/usr/bin/ruby

class CharCounter

  def initialize
    @twos = 0
    @threes = 0
  end

  def add_line(line)
    counts = count_chars(line)
    @twos += 1 if any_repetition?(counts, 2)
    @threes += 1 if any_repetition?(counts, 3)
  end

  def any_repetition?(counts, repeat)
    counts.values.any? {|count| count == repeat}
  end

  def count_chars(line)
    counts = Hash.new { |hash, key| hash[key] = 0 }
    line.chars.each do |char|
      counts[char] += 1
    end
    counts
  end

  def checksum
    @twos * @threes
  end
end

counter = CharCounter.new

File.open(ARGV[0]).each_line do |line|
  counter.add_line(line)
end

puts "checksum: #{counter.checksum}"