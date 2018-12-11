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

  def power_level_of_subgrid(x, y, size)
    sum = 0
    (0...size).each do |dx|
      (0...size).each do |dy|
        sum += corrdinates[y+dy-1][x+dx-1].power_level
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

end

[[122,79, 57], [217,196, 39], [101,153, 71]].each do |x, y, serial|
  puts "Fuel cell at #{x},#{y} and grid serial no #{serial}: #{FuelCell.power_level_at(x, y, serial)}"
end


grid = PowerGrid.new(2694)
puts "highest powered subgrid (3x3): #{grid.max_subgrid_3_by_3}"