#!/usr/bin/ruby

class FuelCell
  attr_reader :power_level

  def initialize(x, y, serial)
    @power_level = self.class.power_level_at(x, y, serial)
  end

  def self.power_level_at(x, y, serial)
    rack_id = x + 10
    power_level = ((rack_id * y) + serial) * rack_id
    power = power_level.to_s.chars.fetch(-3, '0').to_i
    power - 5
  end

end

class PowerGrid
  attr_reader :corrdinates

  def initialize(serial_no)
    @serial_no = serial_no
    @corrdinates = Array.new(300) do |y| 
      Array.new(300) do |x| 
        FuelCell.new(x + 1, y + 1, @serial_no)
      end
    end
  end

  def power_level_at(x, y)
    corrdinates[y-1][x-1].power_level
  end

  def power_level_of_subgrid(x, y, size)
    sum = 0
    (0...size).each do |dx|
      (0...size).each do |dy|
        sum += power_level_at(x+dx, y+dy)
      end
    end
    sum
  end

  def max_subgrid_3_by_3
    max_level = nil
    found_x = nil
    found_y = nil
    (1..298).each do |y|
      (1..298).each do |x|
        power_level = power_level_of_subgrid(x, y, 3)
        if (max_level.nil? || power_level > max_level) 
          max_level = power_level
          found_y = y
          found_x = x
        end
      end
    end
    return found_x, found_y
  end

  def power_level_of_subgrid_edge(x, y, size)
    right_edge_x = (x + size) - 1
    edge_power = (y..(y+size-1)).map do |y|
      power_level_at(right_edge_x, y)
    end.inject(:+)

    if size > 1
      bottom_edge_y = (y + size) - 1
      bottom_edge_power = (x..(x+size-2)).map do |x|
        power_level_at(x, bottom_edge_y)
      end.inject(:+)
      edge_power +=  bottom_edge_power
    end

    edge_power
  end

  def max_subgrid_at(x, y)
    # if any coordinate is at the edge, max_size is 1
    max_power_level = nil
    size_at_max_power = nil
    current_power_level = 0
    max_size = (300 - [x, y].max) + 1
    (1..max_size).each do |size|
      current_power_level += power_level_of_subgrid_edge(x, y, size)
      if max_power_level.nil? || current_power_level > max_power_level
        max_power_level = current_power_level
        size_at_max_power = size
      end
    end
    {power_level: max_power_level, size: size_at_max_power, x: x, y: y}
  end

  def max_subgrid
    found_subgrid = nil
    max_level = nil
    (1..300).each do |y|
      (1..300).each do |x|
        subgrid = max_subgrid_at(x, y)
        puts "max_subgrid_at: #{x},#{y} - #{subgrid[:power_level]} : size #{subgrid[:size]}"
        if (max_level.nil? || subgrid[:power_level] > max_level) 
          max_level = subgrid[:power_level]
          found_subgrid = subgrid
        end
      end
    end
    found_subgrid
  end

end

[[122,79, 57], [217,196, 39], [101,153, 71]].each do |x, y, serial|
  puts "Fuel cell at #{x},#{y} and grid serial no #{serial}: #{FuelCell.power_level_at(x, y, serial)}"
end


grid = PowerGrid.new(2694)
puts "highest powered subgrid (3x3): #{grid.max_subgrid_3_by_3}"
subgrid = grid.max_subgrid
puts "highest powered subgrid: #{subgrid[:x]},#{subgrid[:y]},#{subgrid[:size]} : #{subgrid[:power_level]}"