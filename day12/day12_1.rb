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
    pre_pad = case prefix
    when '..#'
      '.'
    when '.#.', '.##'
      '..'
    when '#..', '##.', '###', '#.#'
      '...'
    else
      ''
    end

    suffix_pad = case suffix
    when '..#'
      '.'
    when '.#.', '.##'
      '..'
    when '#..', '##.', '###', '#.#'
      '...'
    else
      ''
    end

    pre_pad + state + suffix_pad
  end

  def next_state(state)
    new_state = ['.', '.']
    #pots = pad_string(state).chars
    state.chars.each_cons(5) do |tuple|
      # if tuple.join == '.#.#.'
      #   puts "debug #{new_state}"
      # end
      if new_pot = transitions[tuple.join]
        new_state << new_pot
      else
        new_state << '.'
      end
    end
    new_state.concat(['.', '.']).join
  end

  def transform()
    @state = next_state(@state)
  end

end

class PotCounter
  def initialize

  end

  def add_line

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
21.times do |iteration|
  puts "#{iteration}:\t#{pots.state}"
  pots.transform
end

counter = PotCounter.new
if ARGV[0] && File.exists?(ARGV[0])
  File.open(ARGV[0]).each_line do |line|
    counter.add_line(line.strip)
  end
end
