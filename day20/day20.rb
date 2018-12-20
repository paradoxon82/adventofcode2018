#!/usr/bin/ruby

require 'set'

class PathNode
  attr_accessor :parent, :children
  attr_reader :steps

  def initialize(parent = nil)
    @parent = parent
    @steps = []
    @children = []
  end

  def add_child(child)
    child.parent = self
    @children << child
  end

  def add_step(step)
    @steps << step
  end

  def empty?
    @steps.empty?
  end

  # def max_length
  #   length = @steps.size
  #   max_child = @children.map do |child|
  #     child.max_length
  #   end.max
  #   length += max_child if max_child
  #   length
  # end 
end

class PathTree
  attr_reader :start

  def initialize
    @start = PathNode.new
  end

  def max_length
    @start.max_length
  end
end

class Stepper

  def initialize(start_node)
    @start_node = start_node
    # collects the shortest paths to all points on the map
    @shortest_paths = {[0,0] => 0}
  end

  def calculate_shortest_paths
    follow_node(@start_node, [0,0], 0)
  end

  def count_step(step, position, length)
    case step
    when 'N'
      position[1] -= 1
    when 'W'
      position[0] -= 1
    when 'S'
      position[1] += 1
    when 'E'
      position[0] += 1
    else
      raise "Unknown step #{step}"
    end
    # no path yet or shorter path found
    if !@shortest_paths[position] || length < @shortest_paths[position] 
      @shortest_paths[position] = length  
      puts "position #{position} is reachable in #{length} steps"
    end

  end

  def follow_node(node, position, length)
    node.steps.each do |step|
      length += 1
      count_step(step, position, length)
    end
    node.children.each do |child|
      raise "loop found" if node == child 
      follow_node(child, position.clone, length)
    end
  end

  def longest_shortest_path
    furthest_pos, path_length = @shortest_paths.max_by do |pos, lenght| 
      lenght
    end

    path_length
  end

end

class PathFollower

  def register_steps(steps)

    @start_node = current_node = PathNode.new

    steps[1..-2].chars.each do |step|
      if 'WNES'.include?(step)
        current_node.add_step(step)
      elsif step == '('
        node = PathNode.new
        current_node.add_child(node)
        current_node = node
      elsif step == ')'
        # all nodes in the alternatives, have the new node as a follow node
        new_node = PathNode.new
        current_node.parent.children.each do |precursor|
          precursor.add_child(new_node)
        end
        current_node = new_node
      elsif step == '|'
        par = current_node.parent  
        current_node = PathNode.new
        par.add_child(current_node)
      else 
        raise "unrecognized char #{step}"
      end
    end

    
  end

  def longest_shortest_path
    stepper = Stepper.new(@start_node)
    stepper.calculate_shortest_paths
    stepper.longest_shortest_path
  end

end

if (ARGV[0] && File.exists?(ARGV[0]))
  File.open(ARGV[0]).each_line do |line|
    follower = PathFollower.new
    follower.register_steps(line.strip)
    length = follower.longest_shortest_path
    puts "measures: #{length}"
  end
else
  tests = [['^ENNWSWW(NEWS|)SSSEEN(WNSE|)EE(SWEN|)NNN$', 18],
    ['^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$', 23],
    ['^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$', 31]]

  tests.each do |path|
    follower = PathFollower.new
    follower.register_steps(path[0])
    length = follower.longest_shortest_path

    puts "path #{path[0]}, length #{path[1]}"
    puts "measures: #{length}"
  end
end


