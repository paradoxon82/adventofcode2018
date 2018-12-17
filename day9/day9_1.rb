#!/usr/bin/ruby

$verbose = false

class Elf
  attr_reader :number, :score

  def initialize(number)
    @number = number
    @score = 0
  end

  def add_to_score(marble)
    puts "player #{number} gets #{marble} and goes from #{score} to #{score+marble}" if $verbose
    @score += marble
  end

end

class Field
  attr_reader :current_index

  def initialize(first_marble)
    @marbles = [first_marble]
    @current_index = 0
  end

  def place_marble(marble, player)
    if (marble % 23) == 0
      player.add_to_score(marble)
      player.add_to_score(take_counter_clockwise(7))
    else
      place_clockwise(1, marble)
    end
    if $verbose
      marbles_vis = @marbles.map {|m| m.to_s}
      marbles_vis[current_index] = "(#{marbles_vis[current_index]})"
      puts "player #{player.number}, marbles #{marbles_vis}" 
    end
    #puts "place_marble #{marble}, player #{player.number}"
  end

  def take_counter_clockwise(count)
    take_at_index = (current_index - count) % @marbles.size
    ret = @marbles.delete_at(take_at_index)
    @current_index = take_at_index % @marbles.size
    ret
  end

  def place_clockwise(count, marble)
    insert_at = ((current_index + count) % @marbles.size) + 1
    @current_index = insert_at
    @marbles.insert(insert_at, marble)
  end

  def kldsf(count)

  end

end

class Gamekeeper
  attr_reader :current_marble

  def initialize(player_count, last_marble)
    # init players
    @elfs = Array.new(player_count) { |i| Elf.new(i + 1) }
    @last_marble = last_marble
    @current_marble = 0
    @field = Field.new( @current_marble )
  end

  def next_marble
    @current_marble += 1
    # nil is the abort signal
    (@current_marble <= @last_marble) ? @current_marble : nil
  end

  def play_game
    @elfs.cycle do |elf|
      if marble = next_marble
        @field.place_marble(marble, elf)
      else
        break
      end
    end
  end

  def highest_score
    play_game
    winner = @elfs.max_by do |elf| 
      elf.score
    end
    winner.score
  end
end


$verbose = true
examples = [[9, 25]]
examples.each do |players_count, last_marble|
  keeper = Gamekeeper.new(players_count, last_marble)
  puts "#{players_count} players; last marble is worth #{last_marble} points: high score is #{keeper.highest_score}"
end
$verbose = false
examples = [[10, 1618], [13, 7999], [17, 1104], [21, 6111], [30, 5807]]
examples.each do |players_count, last_marble|
  keeper = Gamekeeper.new(players_count, last_marble)
  puts "#{players_count} players; last marble is worth #{last_marble} points: high score is #{keeper.highest_score}"
end

puts "part1:"
input_text = '418 players; last marble is worth 71339 points'
input = [[418, 71339]]
input.each do |players_count, last_marble|
  keeper = Gamekeeper.new(players_count, last_marble)
  puts "#{players_count} players; last marble is worth #{last_marble} points: high score is #{keeper.highest_score}"
end

# takes too long
# puts "part2:"
# input_text = '418 players; last marble is worth 71339 points'
# input = [[418, 71339 * 100]]
# input.each do |players_count, last_marble|
#   keeper = Gamekeeper.new(players_count, last_marble)
#   puts "#{players_count} players; last marble is worth #{last_marble} points: high score is #{keeper.highest_score}"
# end