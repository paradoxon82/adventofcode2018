#!/usr/bin/ruby

$verbose = true

class Pots
  attr_reader :state, :transitions

  def initialize(state, transitions)
    @state = []
    state.chars.each_with_index do |pot, position|
      if pot == '#'
        @state << position
      end
    end

    @transitions = transitions
  end

  def position_range
    (@state.min-3)..(@state.max+3)
  end

  def position_range_unpadded
    @state.min..@state.max
  end

  def string_from(pos_tuple)
    pos_tuple.map do |pos|
      if @state.member? pos
        '#'
      else
        '.'
      end
    end.join
  end

  def next_state(state)
    new_state = []
    position_range.each_cons(5) do |pos_tuple|
      if new_pot = transitions[string_from(pos_tuple)]
        new_state << pos_tuple[2] if new_pot == '#'
      end
    end
    new_state
  end

  def transform()
    @state = next_state(@state)
  end

  def plant_count
    @state.inject(0, :+)
  end

  def state_string
    string_from(position_range_unpadded)
  end

end

class PotCounter
  attr_reader :initial_state

  def initialize
    @initial_state = nil
    @transitions = {}
  end

  def initial_state_regex
    /initial state: (.+)/
  end

  def map_regex
    /(.+) => (.)/
  end

  def set_initial_state(m)
    @initial_state = m[1]
    puts "initial_state #{initial_state}"
  end

  def add_mapping(m)
    @transitions[m[1]] = m[2]
    puts "adding transition #{m[1]} => #{m[2]}"
  end

  def add_line(line)
    if m = initial_state_regex.match(line)
      set_initial_state(m)
    elsif m = map_regex.match(line)
      add_mapping(m)
    end
  end

  def sum_after_generations(generations)
    pots = Pots.new(@initial_state, @transitions)
    generations.times do |iteration|
      pots.transform
      puts "#{iteration}:\t#{pots.state_string}"
    end

    return pots.plant_count
  end
end

inital_state_exaple = '#..#.#..##......###...###'

transitions = {
    '...##' => '#',
    '..#..' => '#',
    '.#...' => '#',
    '.#.#.' => '#',
    '.#.##' => '#',
    '.##..' => '#',
    '.####' => '#',
    '#.#.#' => '#',
    '#.###' => '#',
    '##.#.' => '#',
    '##.##' => '#',
    '###..' => '#',
    '###.#' => '#',
    '####.' => '#'}

pots = Pots.new(inital_state_exaple, transitions)
20.times do |iteration|
  puts "#{iteration}:\t#{pots.state_string}"
  puts "#{iteration}:\t#{pots.state}"

  #puts "plant_count: #{pots.plant_count}"
  pots.transform
end
puts "#{20}:\t#{pots.state_string}"
puts "#{20}:\t#{pots.state}"
puts "sum after 20 generations: #{pots.plant_count}"

counter = PotCounter.new
if ARGV[0] && File.exists?(ARGV[0])
  File.open(ARGV[0]).each_line do |line|
    counter.add_line(line.strip)
  end

  puts "sum after 20 generations: #{counter.sum_after_generations(20)}"
end
