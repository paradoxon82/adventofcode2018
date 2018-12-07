#!/usr/bin/ruby

require 'set'

class StepCollector

  attr_reader :second

  def initialize(workers, base_time)
    @worker_count = workers
    @base_time = base_time
    @worker_assignments = {}
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
      puts "step #{step} finished!"
      @successors[step].each do |successor|
        # remove the ready step from the predecessor list
        @predecessors[successor].delete(step)
      end
      # no successors any more
      @successors[step].clear
      @steps.delete(step)
    end
  end

  def get_steps_with_no_predecessor
    @steps.select do |step|
      # if there are no predecessors, select it
      @predecessors[step].nil? || @predecessors[step].empty?
    end
  end

  def ready_steps_in_alphabet(free_workers)
    ready_steps = get_steps_with_no_predecessor
    # current assignmends should not be returned again
    ready_steps -= @worker_assignments.keys
    if ready_steps.empty?
      nil
    else
      # take as much steps as there are workers
      workable = ready_steps.sort.take(free_workers)
      puts "ready_steps #{ready_steps}, for #{free_workers}, able to work on #{workable}"
      workable
    end
  end

  def finished_steps(seconds)
    @worker_assignments.select do |step, end_time|
      end_time <= seconds
    end.keys
  end

  # get the steps that are finished by now and set them to done, remove them from the assignments
  def mark_jobs_finished(steps)
    set_steps_to_done!(steps)
    steps.each {|step| @worker_assignments.delete(step)}
    # return true if any jobs finished, or no jobs are running
    # steps.size > 0 || @worker_assignments.empty?
  end

  def free_worker_count
    @worker_count - @worker_assignments.size
  end

  def end_time_of(step, current_time)
    extra_time = step.codepoints.first - 64
    current_time + @base_time + extra_time - 1
  end

  def work_on(step, current_time)
    @worker_assignments[step] = end_time_of(step, current_time)
    puts "working on #{step} from #{current_time} until #{@worker_assignments[step]}"
  end

  def work_to_do?
    !@steps.empty?
  end

  def workers_working?
    !@worker_assignments.empty?
  end

  def next_finished_steps!
    # wait for any job finishing
    steps = []
    while steps.size == 0 && workers_working?
      steps = finished_steps(@second)
      mark_jobs_finished(steps)
      @second += 1 # maybe change 1 to a smart value
      # break if any steps finished or nobody is working
    end

    if next_steps = ready_steps_in_alphabet(free_worker_count)
      next_steps.each do |step|
        work_on(step, @second)
      end
    end
    steps.sort
  end

  def step_order
    @second = 0
    ordered_steps = []
    while work_to_do?
      ordered_steps.concat(next_finished_steps!)
    end 
    ordered_steps
  end

end

collector = StepCollector.new(2, 0)
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

collector = StepCollector.new(5, 60)
File.open(ARGV[0]).each_line do |line|
  collector.add_line(line.strip)
end

puts "real step order: #{collector.step_order.join}"
puts "time taken: #{collector.second}"