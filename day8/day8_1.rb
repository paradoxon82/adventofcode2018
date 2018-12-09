#!/usr/bin/ruby

require 'set'

class TreeNode
  attr_reader :name, :metadata_count, :child_count

  def initialize(parent = nil)
    @parent = parent
    @state = :child_count
    @child_nodes = []
    @metadata = []
    @child_count = 0
    @metadata_count = 0
    @name = TreeNode.next_name()
  end

  def self.next_name
    @names ||= ('A'..'Z').to_a
    @names.shift
  end

  def read_metadata!(data)
    @metadata << data
    @state = @metadata_count == @metadata.count ? :full : :read_metadata 
  end

  def consume(data)
    puts "node: #{self.name}, consume #{data}, state #{@state}"
    case @state
    when :child_count
      @child_count = data
      @state = :metadata_count
    when :metadata_count
      @metadata_count = data
      if @child_count == 0
        @state = :read_metadata
      else
        @state = :follow_children
      end
      puts "state after metadata_count #{@state}, #{@child_count}, #{@metadata_count}"
    when :follow_children
      @state = :descent
    when :descent
      if @child_nodes.count == @child_count
        read_metadata!(data)
      end
    when :read_metadata
      read_metadata!(data)
    end

    ret = if @state == :full
      if @parent.nil?
        puts "returning from root #{self.name} and done!"
      else
        puts "returning from #{self.name} to #{@parent.name}"
      end
      
      @parent
    elsif @state == :descent
      child = TreeNode.new(self)
      puts "stepping one child down, from #{self.name} to #{child.name}"
      child.consume(data)
      @child_nodes << child
      child
    else
      self
    end
  end

  def sum_up
    puts "sum_up: children #{@child_count}, metadata_count #{@metadata_count}"
    # @metadata.each do |part|
    #   puts "part #{part}"
    # end
    @metadata.reduce(0, :+) + @child_nodes.reduce(0) do |sum, child|
      sum + child.sum_up
    end
  end
end

class TreeBuilder

  def initialize
    @sequence = []
    @root_node = TreeNode.new
    @current_node = @root_node
  end

  def add_line(line)
    @sequence.concat(line.split)
  end

  def consume_item(item)    
    @current_node = @current_node.consume(item.to_i)
  end

  def follow_nodes
    @sequence.each do |item|
      consume_item(item)
    end
  end

  def metadata_sum
    follow_nodes
    @root_node.sum_up
  end
end


builder = TreeBuilder.new
builder.add_line('2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2')
puts "metadata_sum: #{builder.metadata_sum}"

builder = TreeBuilder.new
File.open(ARGV[0]).each_line do |line|
  builder.add_line(line.strip)
end
puts "answer 1: #{builder.metadata_sum}"