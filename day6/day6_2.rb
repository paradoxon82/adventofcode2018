#!/usr/bin/ruby

require 'set'

#require 'byebug'

class CoordinateCollector

  def initialize(max_dist)
    # to be within region
    @max_dist = max_dist
    @verbose = false
    @ids = ('AA'..'ZZ').to_a
    @coords = {}
    @claimed_area = Hash.new { |hash, key| hash[key] = 0 }
    @max_x = nil
    @max_y = nil
    @min_x = nil
    @min_y = nil
  end

  def next_id
    @ids.shift
  end

  def max(old_max, val)
    if old_max.nil?
      val
    else
      old_max < val ? val : old_max
    end
  end

  def min(old_min, val)
    if old_min.nil?
      val
    else
      old_min > val ? val : old_min
    end
  end

  def register_point(id, x, y)
    @max_x = max(@max_x, x)
    @max_y = max(@max_y, y)
    @min_x = min(@min_x, x)
    @min_y = min(@min_y, y)

    @coords[id] = {x: x, y: y}
  end

  def add_line(line)
    x, y = line.split(',')
    register_point(next_id, x.to_i, y.to_i)
  end

  def dist_to(x, y, point)
    (point[:x]- x).abs + (point[:y]- y).abs
  end

  def min_dist(x, y)
    dists = {}
    @coords.each do |id, point|
      dists[id] = dist_to(x, y, point)
    end

    min_dist = nil 
    nearest_points = []
    dists.each do |id, dist|
      if min_dist.nil? || dist < min_dist
        # new nearest point, clear array
        nearest_points = [id]
        min_dist = dist
      elsif dist == min_dist
        nearest_points << id
      end
    end
    # raise "invalid position #{x}, #{y}" if nearest_points.member?(nil)
    # byebug if nearest_points.member?(nil)
    nearest_points
  end

  def sum_dist(x , y)
    sum = 0
    @coords.each do |id, point|
      sum += dist_to(x, y, point)
    end
    sum
  end

  def at_edge?(x, y)
    x == @min_x || x == @max_x || y == @min_y || y == @max_y
  end

  def safe_region_size
    safe_region = 0
    (@min_y..@max_y).each do |y|
      line = [] if @verbose
      (@min_x..@max_x).each do |x|
        if sum_dist(x, y) < @max_dist
          safe_region += 1
        end
      end
    end
    return safe_region
  end

end

# collector = CoordinateCollector.new
# # File.open(ARGV[0]).each_line do |line|
# #   collector.add_line(line.strip)
# # end

# lines = []
# lines << '1, 1'
# lines << '1, 6'
# lines << '8, 3'
# lines << '3, 4'
# lines << '5, 5'
# lines << '8, 9'

# lines.each do |line|
#  collector.add_line(line.strip)
# end

# point, area = collector.largest_area
# puts "result, point #{point} hast the area #{area}"

collector = CoordinateCollector.new(10000)
File.open(ARGV[0]).each_line do |line|
  collector.add_line(line.strip)
end

area = collector.safe_region_size
puts "result, ssave reagion area #{area}"