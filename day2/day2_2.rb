#!/usr/bin/ruby

class StringDiffer
  def self.difference(a, b)
    diff = 0
    matching = []
    a.chars.zip(b.chars).each do |a_c, b_c|
      if a_c != b_c
        diff += 1 
      else
        matching << a_c
      end
    end
    return matching.join, diff
  end
end

found = false

id_list = []
File.open(ARGV[0]).each_line do |line|
  id_list << line.strip
end

id_one = nil
id_two = nil
found_match = nil

id_list.combination(2).each do |one, two|
  matching, diff = StringDiffer.difference(one, two) 
  if diff == 1
    id_one = one
    id_two = two
    found_match = matching 
    break
  end
end


#puts "sum: #{sum}"
puts "id one: #{id_one}"
puts "id two: #{id_two}"
puts "matching: #{found_match}"