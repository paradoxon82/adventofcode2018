#!/usr/bin/ruby

$verbose = true

class Pots
  attr_reader :state, :transitions

  def initialize(state, transitions)
    @state = state
    @transitions = transitions
  end

  def pad_string(state)
    prefix = state[0..2]
    suffix = state[-3..-1]
    # pre_pad = case prefix
    # when '...'
    #   '.'
    # when '..#'
    #   '.'
    # when '.#.', '.##'
    #   '..'
    # when '#..', '##.', '###', '#.#'
    #   '...'
    # else
    #   ''
    # end

    # suffix_pad = case suffix
    # when '...'
    #   '.'
    # when '..#'
    #   '.'
    # when '.#.', '.##'
    #   '..'
    # when '#..', '##.', '###', '#.#'
    #   '...'
    # else
    #   ''
    # end

    '...' + state + '...'
  end

  def next_state(state)
    new_state = []
    pots = pad_string(state).chars
    pots.each_cons(5) do |tuple|
      # if tuple.join == '.#.#.'
      #   puts "debug #{new_state}"
      # end
      if new_pot = transitions[tuple.join]
        new_state << new_pot
      else
        new_state << '.'
      end
    end
    new_state.join
  end

  def transform()
    @state = next_state(@state)
  end

  def plant_count
    @state.count('#')
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
    sum = pots.plant_count
    generations.times do |iteration|
      pots.transform
      puts "#{iteration}:\t#{pots.state}"
      sum += pots.plant_count
    end

    return sum
  end
end

inital_state_exaple = '...#..#.#..##......###...###............'

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
sum = 0
21.times do |iteration|
  puts "#{iteration}:\t#{pots.state}"
  puts "plant_count: #{pots.plant_count}"
  sum += pots.plant_count
  pots.transform
end
puts "sum after 20 generations: #{sum}"

counter = PotCounter.new
if ARGV[0] && File.exists?(ARGV[0])
  File.open(ARGV[0]).each_line do |line|
    counter.add_line(line.strip)
  end

  puts "sum after 20 generations: #{counter.sum_after_generations(20)}"
end
