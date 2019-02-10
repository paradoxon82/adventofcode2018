#!/usr/bin/ruby

found = false

changes = []
File.open(ARGV[0]).each_line do |line|
  changes << line.to_i
end

frequencies = Hash.new { |hash, key| hash[key] = 0}
frequencies[0] = 1

sum = 0
found_frequency = nil
loop = 0
while true
  puts "loop #{loop}"
  loop += 1
  changes.each do |change|
    sum += change
    frequencies[sum] += 1
#    puts "#{sum}"
    if frequencies[sum] > 1
      found_frequency = sum
      break
    end
  end
  break if found_frequency
end



#puts "sum: #{sum}"
puts "first frequency twice: #{found_frequency}"
