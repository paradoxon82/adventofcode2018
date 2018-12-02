#!/usr/bin/ruby

sum = 0

File.open(ARGV[0]).each_line do |line|
  change = line.to_i
  sum += change
end

puts "sum: #{sum}"