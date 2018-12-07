#!/usr/bin/ruby

require 'set'

class StepCollector

  def initialize
    @predecessors = Hash.new { |hash, key| hash[key] = []}
    @successors = Hash.new { |hash, key| hash[key] = [] }
    @steps = Set.new
  end

  def match_line(line)
    /Step (?<predecessor>\w+) must be finished before step (?<successor>\w+) can begin./.match(line)
  end

  def add_line(line)
    if m = match_line(line)
      @steps.merge([m[:successor], m[:predecessor]])
      @predecessors[m[:successor]] << m[:predecessor]
      @successors[m[:predecessor]] << m[:successor]
    else
      raise "unable to parse line: #{line}"
    end
  end

  # all steps that follow the ready steps have one less predecessor now
  # they will become ready if the predecessor array is empty for them
  def set_steps_to_done!(ready_steps)
    ready_steps.each do |step|
      @successors[step].each do |successor|
        # remove the ready step from the predecessor list
        @predecessors[successor].delete(step)
      end
      # no successors any more
      @successors[step].clear
    end
  end

  def get_steps_with_no_predecessor
    @steps.select do |step|
      # if there are no predecessors, select it
      @predecessors[step].nil? || @predecessors[step].empty?
    end
  end

  def first_ready_step_in_alphabet
    ready_steps = get_steps_with_no_predecessor
    puts "ready_steps #{ready_steps}"
    if ready_steps.empty?
      nil
    else
      ready_steps.sort.first
    end
  end

  def next_ready_step!
    next_step = first_ready_step_in_alphabet
    if next_step
      @steps.subtract([next_step])
      set_steps_to_done!([next_step])
    else
      nil
    end
  end

  def step_order
    ordered_steps = []
    while step = next_ready_step!
      ordered_steps << step
    end 
    ordered_steps
  end

end

collector = StepCollector.new
# File.open(ARGV[0]).each_line do |line|
#   collector.add_line(line.strip)
# end
[
'Step C must be finished before step A can begin.',
'Step C must be finished before step F can begin.',
'Step A must be finished before step B can begin.',
'Step A must be finished before step D can begin.',
'Step B must be finished before step E can begin.',
'Step D must be finished before step E can begin.',
'Step F must be finished before step E can begin.',
].each do |line|
  collector.add_line(line)
end

puts "example step order: #{collector.step_order.join}"

collector = StepCollector.new
File.open(ARGV[0]).each_line do |line|
  collector.add_line(line.strip)
end

puts "real step order: #{collector.step_order.join}"