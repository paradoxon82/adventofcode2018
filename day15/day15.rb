#!/usr/bin/ruby

require 'set'
require 'pry'

$verbose = true

class Wall

  def initialize
  end

  def char
    '#'
  end

end

class Unit < Wall

  def initialize()
    super
    @hp = 200
    @ap = 3
  end

end

class Elf < Unit
  attr_reader :char, :type

  def initialize
    @char = 'E'
    @type = :elf
  end

end

class Goblin < Unit
  attr_reader :char, :type

  def initialize
    @char = 'G'
    @type = :goblin
  end

end

class Field

  def initialize()
    @walls = {}
    @units = {}
  end

  def add_unit(unit, x, y)
    position = position(x, y)
    raise "position taken: #{position}" if unit_at(position)
    puts "place unit #{unit.char} at #{position}" if $verbose
    @units[position] = unit
  end

  def add_wall(unit, x, y)
    position = position(x, y)
    raise "position taken: #{position}" if unit_at(position)
    puts "place wall at #{position}" if $verbose
    @walls[position] = unit
  end

  def unit_at(position)
    @units[position]
  end

  def wall_at(position)
    @walls[position]
  end

  def position_taken?(position)
    @walls.member?(position) || @units.member?(position)
  end

  def position(x, y)
    [y, x]
  end

  def thing_at_pos(position)
    wall_at(position) || unit_at(position)
  end

  def thing_at(x, y)
    position = position(x, y)
    thing_at_pos(position)
  end

  def max_x
    [@walls.keys.map(&:first).max, 
    @units.keys.map(&:first).max].max
  end

  def max_y
    [@walls.keys.map(&:last).max,
    @units.keys.map(&:last).max].max
  end

  def print_field
    (0..max_y).each do |y|
      line = []
      (0..max_x).each do |x|
        thing = thing_at(x, y)
        if thing
          line << thing.char
        else
          line << '.'
        end
      end
      puts line.join
    end
  end

  def units_by_order
    @units.sort_by do |position, unit|
      position
    end
  end

  # def goblins
  #   units_by_order.filter {|position, unit| unit.type == :goblin}
  # end

  def units_of_type(type)
    units_by_order.filter {|position, unit| unit.type == type}
  end

  def first_enemy_in_range(position, unit)
    enemies
    if unit.type == :elf
      enemies = units_of_type(:goblin)
    elsif unit.type == :goblin
      enemies = units_of_type(:elf)
    else
      raise "unknown type #{unit.type}"
    end

    free_enemies = enemies.filter { |pos, unit| unit_free?(pos) }
    nearest_enemies = free_enemies.sort_by { |enemy_pos, unit| distance(position, enemy_pos) }
    nearest_enemies_sorted = nearest_enemies.sort_by { |enemy_pos, unit| enemy_pos }

    nearest_enemies_sorted.first
  end

  def pos_step(pos, step)
    [pos.first + step.first, pos.last + step.last]
  end

  def distance(from, to)
    # TODO implement
  end

  def unit_free?(position)
    # any adjacent free space
    [[-1, 0], [1, 0], [0, -1], [0, 1]].any? do |move|
      new_pos = pos_step(position, move)
      thing_at_pos(new_pos).nil?
    end
  end

  def next_step
    any_action = false
    units_by_order.each do |position, unit|
      enemy = adjacent_enemy(position, unit)
      if enemy
        unit.fight_with(enemy)
      else
        enemy = first_enemy_in_range(position, unit)
      end
      unless enemy
        next
      end
    end
    return any_action
  end

end

class FieldParser
  attr_reader :field, :current_y

  def initialize
    @field = Field.new
    @current_y = 0
  end

  def advance_x 
    @current_y += 1
  end

  def add_unit(unit, x)
    field.add_unit(unit, x, current_y)
  end

  def add_position(unit, x)
    field.add_wall(unit, x, current_y)
  end

  def register_line(line)
    line.chars.each_with_index do |char, i|
      if char == '#'
        add_position Wall.new, i
      elsif char == 'E'
        add_unit Elf.new, i
      elsif char == 'G'
        add_unit Goblin.new, i
      end
    end
    advance_x()
  end

  def max_x
    field.max_y
  end

  def max_y
    field.max_x
  end

  def print_field
    field.print_field
  end

  def next_step
    field.next_step
  end

  def do_battle
    while next_step
      print_field
    end
  end

end


parser = FieldParser.new
lines = []

if (ARGV[0] && File.exists?(ARGV[0]))
  File.open(ARGV[0]).each_line do |line|
    lines << line.strip
  end
else
  # example = ["#########",
  #           "#G..G..G#",
  #           "#.......#",
  #           "#.......#",
  #           "#G..E..G#",
  #           "#.......#",
  #           "#.......#",
  #           "#G..G..G#",
  #           "#########"]

  lines = [
    "#######",   
    "#.G...#",   #G(200)
    "#...EG#",   #E(200), G(200)
    "#.#.#G#",   #G(200)
    "#..G#E#",   #G(200), E(200)
    "#.....#",   
    "#######", 
  ]
end

lines.each do |line|
  parser.register_line(line)
end

parser.print_field