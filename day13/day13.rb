#!/usr/bin/ruby

$verbose = true

class Cart
  attr_reader :direction

  def initialize(direction)
    @direction = direction
    @turns = [:left, :straight, :right]
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

    change_pos = case new_direction
    when :up
      {dy: -1}
    when :down
      {dy: 1}
    when :right
      {dx: 1}
    when :left
      {dx: -1}
    else
        raise "Illegal track_orientation #{track_orientation} for direction #{direction}"
    end

    @direction = new_direction
    # switch to the next turn
    @turns.rotate!
    {dx: 0, dy: 0, direction: direction}.merge(change_pos)
  end

  def position_delta(track_orientation)
    change = case track_orientation 
    when :horizontal  
      case direction
      when :left
        {dx: -1}
      when :right
        {dx: 1}
      else
        raise "Illegal track_orientation #{track_orientation} for direction #{direction}"
      end
    when :vertical
      case direction
      when :up
        {dy: -1}
      when :down
        {dy: 1}
      else
        raise "Illegal track_orientation #{track_orientation} for direction #{direction}"
      end
    when :crossing
      change_at_crossing
    when :slash #'/'
      case direction
      when :up
        {dx: 1,dy: -1, direction: :right}
      when :left
        {dx: -1,dy: 1, direction: :down}
      when :right
        {dx: 1, dy: -1, direction: :up}
      when :down
        {dx: -1, dy: 1, direction: :left}
      else
        raise "Illegal track_orientation #{track_orientation} for direction #{direction}"
      end
    when :backslash #'\\'
      case direction
      when :up
        {dx: -1,dy: -1, direction: :left}
      when :left
        {dx: -1,dy: -1, direction: :up}
      when :right
        {dx: 1, dy: 1, direction: :down}
      when :down
        {dx: 1, dy: 1, direction: :right}
      else
        raise "Illegal track_orientation #{track_orientation} for direction #{direction}"
      end
    else
      raise "orientation #{track_orientation} unknown"
    end

    chage_to_cart = {dx: 0, dy: 0, direction: direction}.merge(change)
  end
end

class Track
  attr_reader :orientation

  def initialize(orientation)
    @orientation = orientation
  end
end

class CartPaths

  # distinquish roads and carts
#   |  |  |  |
# \--+--/

  def initialize
    @cart_positions = Hash.new { |hash, key| hash[key] = {} }
    @road_positions = Hash.new { |hash, key| hash[key] = {} }
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
    
    @road_positions[row][column] = Track.new(orientation)
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
    puts "starting cart at #{row},#{column}, direction #{direction}"
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

  def reposition_cart(row, column, postition_change)
    cart = @cart_positions[row].delete(column)
    row_new = row + postition_change[:dy]
    column_new = column + postition_change[:dx]
    @cart_positions[row_new][column_new] = cart
  end

  def move_cart(cart, row, column)
    if track_orientation = @road_positions[row][column].orientation
      puts "moving cart at #{row},#{column}"
      postition_change = cart.position_delta(track_orientation)
      reposition_cart(row, column, postition_change)
    else
      raise "cart got of tracks at #{row},#{column}"
    end
  end

  def next_step
    @cart_positions.keys.sort.each do |row|
      @cart_positions[row].keys.sort.each do |column|
        move_cart(@cart_positions[row][column], row, column)
      end
    end
  end

  def first_crash
    next_step
    0
  end
end

if ARGV[0] && File.exists?(ARGV[0])
  tracks = CartPaths.new
  File.open(ARGV[0]).each_line.with_index do |line, row|
    tracks.add_line(line, row)
  end
  
  puts "first crash at: #{tracks.first_crash}"
end
