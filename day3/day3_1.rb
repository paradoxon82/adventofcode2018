#!/usr/bin/ruby


class CoordinateChecker

  def initialize()
    @cloth = Array.new(1000) do |i| 
      Array.new(1000) { |j| [] } 
    end
  end

  # #1 @ 1,3: 4x4
  def match_line(line)
    /#(?<id>\d+)\D@\D(?<x>\d+),(?<y>\d+):\D(?<width>\d+)x(?<height>\d+).*/.match(line)
  end

  def parse_line(line)
    if m = match_line(line)
      {
        x: m[:x].to_i,
        y: m[:y].to_i,
        width: m[:width].to_i,
        height: m[:height].to_i,
        id: m[:id]
      }
    else
      nil
    end
  end

  def register_claim(claim)
    start_x = claim[:x]
    start_y = claim[:y]
    end_x = claim[:x] + claim[:width] - 1
    end_y = claim[:y] + claim[:height] - 1
    #puts "accessing #{start_x..end_x} and #{start_y..end_y}"

    @cloth[start_x..end_x].each_with_index do |strip, i|
      strip[start_y..end_y].each_with_index do |entry, j|
        #puts "already at #{i}x#{j}: #{entry}" unless entry.empty?
        entry << claim[:id]
      end
    end
  end

  def add_line(line)
    m = parse_line(line)
    if m
      register_claim(m)
    else
      raise "unable to parse line #{line}"
    end
  end

  def overlap_count
    @cloth.reduce(0) do |count, strip|
      count += strip.count do |entry|
        entry.size > 1
      end
    end
  end

end

checker = CoordinateChecker.new
File.open(ARGV[0]).each_line do |line|
  checker.add_line(line)
end

puts "overlap count: #{checker.overlap_count}"