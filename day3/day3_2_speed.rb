#!/usr/bin/ruby

require 'set'

Claim = Struct.new(:x, :y, :width, :height, :id)

class CoordinateChecker

  def initialize()
    @cloth = Array.new(1000) do |i| 
      Array.new(1000) { |j| [] } 
    end
    @ids = Set.new
    @id_conflict = Hash.new { |hash, key| hash[key] = false }
  end

  def line_regex
    @line_regex ||= /#(?<id>\d+)\D@\D(?<x>\d+),(?<y>\d+):\D(?<width>\d+)x(?<height>\d+).*/
  end

  # #1 @ 1,3: 4x4
  def match_line(line)
    parts = line.split(/\D/).reject { |s| s.empty? }
    if parts.size == 5
      parts
    else
      nil
    end
  end

  def build_claim(m)
    Claim.new(m[1].to_i, m[2].to_i, m[3].to_i, m[4].to_i, m[0].to_i)
  end

  def parse_line(line)
    if m = match_line(line)
      build_claim(m)
    else
      nil
    end
  end

  def register_claim(claim)
    @ids << claim.id
    @id_conflict[claim.id] = false
    start_x = claim.x
    start_y = claim.y
    end_x = claim.x + claim.width - 1
    end_y = claim.y + claim.height - 1
    #puts "accessing #{start_x..end_x} and #{start_y..end_y}"

    @cloth[start_x..end_x].each do |strip|
      strip[start_y..end_y].each do |entry|
        #puts "already at #{i}x#{j}: #{entry}" unless entry.empty?
        entry << claim.id
        if entry.size > 1
          entry.each do |id|
            @id_conflict[id] = true
          end
        end

        #@id_count[claim[:id]] = 2 if entry.size > 1
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


  def ids_without_overlap2
    id, conflict = @id_conflict.find do |id, conflict|
      conflict == false
    end
    id
  end

end

checker = CoordinateChecker.new
File.open(ARGV[0]).each_line do |line|
  checker.add_line(line)
end

puts "overlap count: #{checker.overlap_count}"
puts "ids without overlap: #{checker.ids_without_overlap2}"