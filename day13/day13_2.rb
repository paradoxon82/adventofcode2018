#!/usr/bin/ruby

$verbose = false

class Cart
  attr_accessor :moved

  def initialize(dir)
    set_direction(dir)
    @turns = [:left, :straight, :right]
    @moved = false
    #puts "cart direction #{direction}, #{self.object_id}"
  end

  def direction
    raise "unknown direction for cart #{@direction}, #{self.object_id}" unless orientation_map.keys.member?(@direction)
    @direction
  end

  def set_direction(dir)
    raise "unknown direction for cart #{dir}" unless orientation_map.keys.member?(dir)
    @direction = dir
  end

  def orientation_map
    {
      up: '^',
      down: 'v',
      right: '>',
      left: '<'
    }
  end

  def symbol
    orientation_map.fetch(direction, '?')
  end

  def change_at_crossing
    current_turn = @turns.first

    new_direction = case current_turn
    when :straight
      direction
    when :left
      case direction
      when :up
        :left
      when :down
        :right
      when :left
        :down
      when :right
        :up
      end
    when :right
      case direction
      when :up
        :right
      when :down
        :left
      when :left
        :up
      when :right
        :down
      end
    end

    # switch to the next turn
    @turns.rotate!
    new_direction
  end

  def position_delta(track_orientation)
    change = case direction
    when :left
      raise "Illegal move #{direction} on track #{track_orientation}" if track_orientation == :vertical
      {dx: -1}
    when :right
      raise "Illegal move #{direction} on track #{track_orientation}" if track_orientation == :vertical
      {dx: 1}
    when :up
      raise "Illegal move #{direction} on track #{track_orientation}" if track_orientation == :horizontal
      {dy: -1}
    when :down
      raise "Illegal move #{direction} on track #{track_orientation}" if track_orientation == :horizontal
      {dy: 1}
    else
      raise "Illegal direction '#{direction}'"
    end

    chage_to_cart = {dx: 0, dy: 0}.merge(change)

  end

  def reorient(track_orientation)
    new_direction = case track_orientation
    when :crossing
      change_at_crossing
    when :slash #'/'
      case direction
      when :up
        :right
      when :left
        :down
      when :right
        :up
      when :down
        :left
      else
        raise "Illegal track_orientation #{track_orientation} for direction #{direction}"
      end
    when :backslash #'\\'
      case direction
      when :up
        :left
      when :left
        :up
      when :right
        :down
      when :down
        :right
      else
        raise "Illegal track_orientation #{track_orientation} for direction #{direction}"
      end
    when :horizontal, :vertical
      # do nothing
      direction
    else
      raise "orientation #{track_orientation} unknown"
    end
    set_direction(new_direction)
  end

end

class Track
  attr_reader :orientation, :symbol

  def initialize(orientation, symbol)
    @orientation = orientation
    @symbol = symbol
  end
end

class CartCrashException < StandardError
  # def initilalize(row, column)
  #   @row = row
  #   @column = column
  # end

  # def message
  #   "Cart crash at #{row},#{column}"
  # end
end

class LastCartException < StandardError

end

class CartPaths

  # distinquish roads and carts
#   |  |  |  |
# \--+--/

  def initialize
    @cart_positions = Hash.new { |hash, key| hash[key] = {} }
    @road_positions = Hash.new { |hash, key| hash[key] = {} }
  end

  def max_row
    [@cart_positions.keys.max, @road_positions.keys.max].max
  end

  def max_column
    max_col = nil
    @cart_positions.each do |row, cols|
      local_max = cols.keys.max
      next unless local_max
      max_col = (max_col.nil? || (max_col < local_max)) ? local_max : max_col
    end

    @road_positions.each do |row, cols|
      local_max = cols.keys.max
      next unless local_max
      max_col = (max_col.nil? || (max_col < local_max)) ? local_max : max_col
    end
    max_col
  end

  def char_at(row, column)
    if @cart_positions[row].member?(column)
      @cart_positions[row][column].symbol
    elsif @road_positions[row].member?(column)
      @road_positions[row][column].symbol
    else
      ' '
    end
  end

  def register_road(orientation_char, row, column)
    
    orientation = case orientation_char
    when '-'
      :horizontal  
    when '|'
      :vertical
    when '+'
      :crossing
    when '/'
      :slash
    when '\\'
      :backslash
    else
      raise "orientation #{orientation_char} for road at #{row},#{column} could not be parsed"
    end
    
    @road_positions[row][column] = Track.new(orientation, orientation_char)
  end

  def register_cart(direction_char, row, column)
    direction = nil
    road_char = nil
    case direction_char
    when '<'
      direction = :left
      road_char = '-'
    when '>'
      direction = :right
      road_char = '-'
    when '^'
      direction = :up
      road_char = '|'
    when 'v'
      direction = :down
      road_char = '|'
    else
      raise "direction #{direction_char} for cart at #{row},#{column} could not be parsed"
    end
    puts "starting cart at #{row},#{column}, direction #{direction}" if $verbose
    @cart_positions[row][column] = Cart.new(direction)
    register_road(road_char, row, column)
  end

  def register_char(char, row, column)
    #puts "char #{char} at #{row},#{column}" if char != ' '
    case char
    when '-','|','+','/','\\'
      register_road(char, row, column)
    when '<', '>', '^', 'v'
      register_cart(char, row, column)
    end

  end

  def add_line(line, row)
    line.chars.each_with_index do |char, column|
      register_char(char, row, column)
    end
  end

  def cart_crash_at(row, column)
    if true
      @cart_positions[row].delete(column)
      puts "took out cart at #{row},#{column}"
    else
      raise CartCrashException, "Cart crash at #{column_new},#{row_new}"
    end
  end

  def reposition_cart(row, column, postition_change)
    cart = @cart_positions[row].delete(column)
    row_new = row + postition_change[:dy]
    column_new = column + postition_change[:dx]

    puts "moving cart at #{row},#{column} to #{row_new},#{column_new}" if $verbose

    if @cart_positions[row_new][column_new]
      cart_crash_at(row_new, column_new)
    else
      @cart_positions[row_new][column_new] = cart
    end
    return row_new, column_new
  end

  def move_cart(cart, row, column)
    if track_orientation = @road_positions[row][column].orientation
      postition_change = cart.position_delta(track_orientation)
      row_new, column_new = reposition_cart(row, column, postition_change)
      raise "no road at #{row_new},#{column_new}" unless @road_positions[row_new][column_new]
      cart.reorient(@road_positions[row_new][column_new].orientation)
      cart.moved = true
    else
      raise "cart got of tracks at #{row},#{column}"
    end
  end

  def set_carts_to_unmoved
    @cart_positions.each do |row, cols|
      cols.each do |col, cart|
        cart.moved = false
      end
    end
  end

  def check_track_integrity
    positions = @cart_positions.flat_map do |row, cols|
      cols.map do |col, cart|
        {row: row, column: col}
      end
    end.compact
     
    if positions.size == 1
      pos = positions.first
      raise LastCartException, "Last cart at #{pos[:column]},#{pos[:row]}"
    end
    raise "no carts found!" if positions.empty?
  end

  def next_step
    set_carts_to_unmoved
    check_track_integrity
    @cart_positions.keys.sort.each do |row|
      @cart_positions[row].keys.sort.each do |column|
        # this happens because we remove crashing carts in the move_cart method, so the column is no longer valid
        next unless @cart_positions[row].member?(column)
        next if @cart_positions[row][column].moved
        move_cart(@cart_positions[row][column], row, column)
      end
    end
  end

  def print_state
    (0..max_row).each do |row|
      line = (0..max_column).map do |col|
        char_at(row,col)
      end.join
      puts line
    end
  end

  def first_crash
    print_state if $verbose
    100000.times do |step| 
      begin
        next_step
        print_state if $verbose
      rescue CartCrashException => e
        puts "iteration #{step}"
        puts e.message
        exit 0
      rescue LastCartException => e
        puts "iteration #{step}"
        puts e.message
        exit 0
      # rescue Exception => e
      #   puts e
      #   exit 1
      end
    end
    0
  end
end

if ARGV[0] && File.exists?(ARGV[0])
  tracks = CartPaths.new
  File.open(ARGV[0]).each_line.with_index do |line, row|
    tracks.add_line(line, row)
  end
  
  puts "first crash at: #{tracks.first_crash}"

else
  example = [
'/->-\\        ',
'|   |  /----\\',
'| /-+--+-\\  |',
'| | |  | v  |',
'\\-+-/  \\-+--/',
'  \\------/   ']
  
  tracks = CartPaths.new
  example.each_with_index do |line, row|
    tracks.add_line(line, row)
  end

  puts "first crash at: #{tracks.first_crash}"

end
