#!/usr/bin/ruby

require 'set'

class PathNode
  attr_accessor :parent

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

  def set_detour
    @children.clear
  end

  def max_length
    length = @steps.size
    max_child = @children.map do |child|
      child.max_length
    end.max
    length += max_child if max_child
    length
  end 
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

class PathFollower

  def longest_path(steps)

    tree = PathTree.new
    current_node = tree.start

    steps[1..-2].chars.each do |step|
      if 'WNES'.include?(step)
        current_node.add_step(step)
      elsif step == '('
        node = PathNode.new
        current_node.add_child(node)
        current_node = node
      elsif step == ')'
        if current_node.empty?
          current_node = current_node.parent
          current_node.set_detour
        else
          current_node = current_node.parent
        end
      elsif step == '|'
        par = current_node.parent  
        current_node = PathNode.new
        par.add_child(current_node)
      else 
        raise "unrecognized char #{step}"
      end
    end

    tree.max_length
  end

end

tests = [['^ENNWSWW(NEWS|)SSSEEN(WNSE|)EE(SWEN|)NNN$', 18],
  ['^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$', 23],
  ['^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$', 31]]

follower = PathFollower.new
tests.each do |path|
  length = follower.longest_path(path[0])
  puts "path #{path[0]}, length #{path[1]}"
  puts "measures: #{length}"
end