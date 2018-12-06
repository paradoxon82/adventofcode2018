#!/usr/bin/ruby

require 'set'


class CoordinateCollector

  def initialize
    @ids = ('A'..'Z').to_a
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

    @coords[next_id] = {x: x, y: y}
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
    nearest_points
  end

  def at_edge?(x, y)
    x == @min_x || x == @max_x || y == @min_y || y == @max_y
  end

  def largest_area
    ignored_points = Set.new

    (@min_x..@max_x).each do |x|
      (@min_y..@max_y).each do |y|
        nearest_points = min_dist(x, y)
        if at_edge?(x, y)
          ignored_points.merge(nearest_points)
        end
        if nearest_points.size == 1
          @claimed_area[nearest_points.first] += 1
        else
          #equidistance points are ignored
        end
      end
    end
    puts "claimed_area #{@claimed_area}"
    puts "ignored points: #{ignored_points.to_a}"

    @claimed_area.delete_if {|id, area| ignored_points.member? id}

    point, area = @claimed_area.max_by {|id, area| area}

    return point, area
  end

end

collector = CoordinateCollector.new
File.open(ARGV[0]).each_line do |line|
  collector.add_line(line.strip)
end

point, area = collector.largest_area
puts "result, point #{point} hast the area #{area}"