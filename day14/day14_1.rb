#!/usr/bin/ruby

$verbose = false

class RecipeCreator
  attr_reader :pos1, :pos2, :size

  def initialize(iterations)
    @recipies = Array.new(iterations) { |i| nil }
    @recipies[0..1] = [3, 7]
    @size = 2
    @pos1 = 0
    @pos2 = 1
  end

  def score1 
    @recipies[pos1]
  end

  def score2
    @recipies[pos2]
  end

  def new_recipies
    list = (score1 + score2).to_s.split('').map(&:to_i)
    @recipies[size...(list.size + size)] = list
    @size += list.size
    #puts "new size  #{@size}"
  end

  def next_step
    new_recipies
    #puts "old pos #{@pos1}, #{@pos2}, size #{size}"
    @pos1 = (@pos1 + score1 + 1) % size
    @pos2 = (@pos2 + score2 + 1) % size
    #puts "new pos #{@pos1}, #{@pos2}"
  end

  def print_state
    print_part(@recipies, size)
  end

  def print_part(state, state_size = -1)
    if state_size == -1
      state_size = state.size
    end
    out = Array.new(state_size) do |i| 
      if i == pos1
        "(#{score1})"
      elsif i == pos2
        "[#{score2}]"
      else
        state[i].to_s
      end
    end
    puts out.join(' ')
  end

  def print_last(part_size)
    part = @recipies[(size-part_size)...size]
    print_part(part)
  end

  def step_until(end_size)
    while size < end_size
      next_step
    end
  end
 
end


iterations = 47801

creator = RecipeCreator.new(iterations + 10)
20.times do |iter|
  creator.print_state
  creator.next_step
end
puts "begin stepping.."
creator.step_until(iterations + 10)
creator.print_last(10)