#!/usr/bin/ruby

class Star
  attr_reader :x, :y, :dx, :dy

  def initialize(x, y, dx, dy)
    @x = x
    @y = y
    @dx = dx
    @dy = dy
  end

  def move_step
    @x += @dx
    @y += @dy
  end
end

class Starfield
  attr_reader :min_x, :max_x, :min_y, :max_y

  def initialize
    @stars = []
    @min_x = @min_y = @max_x = @max_y = nil
  end

  def parse_line(line)
    /position=<\s*(?<px>-?[[:digit:]]+)\s*,\s*(?<py>-?[[:digit:]]+)\s*> velocity=<\s*(?<dx>-?[[:digit:]]+)\s*,\s*(?<dy>-?[[:digit:]]+)\s*>/.match(line)
  end

  def add_line(line)
    if m = parse_line(line)
      @stars << Star.new(m[:px].to_i, m[:py].to_i, m[:dx].to_i, m[:dy].to_i)
    else
      raise "unable to parse line: #{line}"
    end
  end

  def calculate_dimensions
    x_list = @stars.map(&:x)
    y_list = @stars.map(&:y)
    return x_list.min, y_list.min, x_list.max, y_list.max
  end

  def set_dimensions
    unless @min_x
      @min_x, @min_y, @max_x, @max_y = calculate_dimensions  
      puts "x: #{min_x} .. #{max_x}"
      puts "y: #{min_y} .. #{max_y}"
    end
  end

  def move_step
    @stars.each do |star|
      star.move_step
    end
  end

  def print_stars
    set_dimensions
    field = Array.new(max_y - min_y + 1) { |i| Array.new(max_x - min_x + 1) { |i| '.' } }
    puts "init starfield with dimensions #{max_x - min_x + 1} x #{max_y - min_y + 1}"
    @stars.each do |star|
      #puts "putting star #{star.x} - #{star.y} at relative position #{star.x - min_x} - #{star.y - min_y}"
      field[star.y - min_y][star.x - min_x] = '#'
    end
    field.each do |line|
      puts "#{line.join}"
    end
  end
end

example = ['position=< 9,  1> velocity=< 0,  2>',
          'position=< 7,  0> velocity=<-1,  0>',
          'position=< 3, -2> velocity=<-1,  1>',
          'position=< 6, 10> velocity=<-2, -1>',
          'position=< 2, -4> velocity=< 2,  2>',
          'position=<-6, 10> velocity=< 2, -2>',
          'position=< 1,  8> velocity=< 1, -1>',
          'position=< 1,  7> velocity=< 1,  0>',
          'position=<-3, 11> velocity=< 1, -2>',
          'position=< 7,  6> velocity=<-1, -1>',
          'position=<-2,  3> velocity=< 1,  0>',
          'position=<-4,  3> velocity=< 2,  0>',
          'position=<10, -3> velocity=<-1,  1>',
          'position=< 5, 11> velocity=< 1, -2>',
          'position=< 4,  7> velocity=< 0, -1>',
          'position=< 8, -2> velocity=< 0,  1>',
          'position=<15,  0> velocity=<-2,  0>',
          'position=< 1,  6> velocity=< 1,  0>',
          'position=< 8,  9> velocity=< 0, -1>',
          'position=< 3,  3> velocity=<-1,  1>',
          'position=< 0,  5> velocity=< 0, -1>',
          'position=<-2,  2> velocity=< 2,  0>',
          'position=< 5, -2> velocity=< 1,  2>',
          'position=< 1,  4> velocity=< 2,  1>',
          'position=<-2,  7> velocity=< 2, -2>',
          'position=< 3,  6> velocity=<-1, -1>',
          'position=< 5,  0> velocity=< 1,  0>',
          'position=<-6,  0> velocity=< 2,  0>',
          'position=< 5,  9> velocity=< 1, -2>',
          'position=<14,  7> velocity=<-2,  0>',
          'position=<-3,  6> velocity=< 2, -1>']

field = Starfield.new
example.each do |line|
  field.add_line(line.strip)
end
5.times do 
  field.print_stars
  field.move_step
  puts 
end


field = Starfield.new
File.open(ARGV[0]).each_line do |line|
  field.add_line(line.strip)
end
5.times do 
  field.print_stars
  field.move_step
  puts 
end