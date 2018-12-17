#!/usr/bin/ruby

$verbose = false

class RecipeCreator
  attr_reader :pos1, :pos2, :size

  def initialize(iterations)
    @recipies = Array.new
    @recipies[0..1] = [3, 7]
    @size = 2
    @pos1 = 0
    @pos2 = 1
    @last_increase = nil
    @fount_at_step_back = nil
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
    @last_increase = list.size
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

  def sequence_found_at?(key_sequence, pos)
    return false if (size + pos) < key_sequence.size

    key_sequence.each_with_index do |c, i|
      return false if @recipies[i+pos] != c
    end

    true


    #puts "#{pos}...#{(pos+key_sequence.size)} #{in_recipies} vs #{key_sequence}, full size #{@recipies.size}"
    # if @recipies[pos...(pos+key_sequence.size)].size != key_sequence.size
    #   raise "error size #{in_recipies.size} vs #{key_sequence.size}"
    # end

    # in_recipies.each_with_index do |c, i|
    #   if c.class != key_sequence[i].class
    #     raise "error"
    #   end
    # end

    # @recipies[pos...(pos+key_sequence.size)] == key_sequence
  end

  def sequence_found?(key_sequence, step_back)
    return false unless step_back
    
    step_back.times do |step|
      #puts "step_back #{step}"
      if sequence_found_at?(key_sequence, size-key_sequence.size-step)
        @fount_at_step_back = step
        return true
      end
    end
    false
  end

  def step_until_sequence(key_sequence)
    while !sequence_found?(key_sequence, @last_increase)
      next_step
      if (size % 10000) == 0
        puts "at step #{size}"
      end
    end
  end

  def count_left_of_key(key_sequence)
    puts "#{size} - #{key_sequence.size} - #{@fount_at_step_back}"
    size - key_sequence.size - @fount_at_step_back
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

key_sequence = '047801'.split('').map(&:to_i)

creator = RecipeCreator.new(100000000)
creator.step_until_sequence(key_sequence)
puts "left of key_sequence: #{creator.count_left_of_key(key_sequence)}"