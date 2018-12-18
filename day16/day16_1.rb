#!/usr/bin/ruby

require 'set'

class Registerstate
  attr_reader :state

  def initialize(state)
    @state = state.map(&:to_i)
    raise "Illegal state length" if state.size != 4
  end

  def get(pos)
    if pos >= 0 && pos < 4
      @state[pos]
    else
      raise "Illegal access to pos #{pos}"
    end
  end

  def set(pos, val)
    if pos >= 0 && pos < 4
      @state[pos] = val
    else
      raise "Illegal access to pos #{pos}"
    end
  end

  def clone
    self.class.new(@state.clone)
  end

  def ==(other)
    if other.class == Registerstate
      @state == other.state
    else
      false
    end
  end

  def to_s
    @state.to_s
  end
end

class Operation
  attr_reader :name
  # access can be :immediate or :register
  def initialize(name, access1, access2, operator, op_type=:numeric)
    @name = name
    @access1 = access1
    @access2 = access2
    @operator = operator
    @op_type = op_type
    raise "unknown access1 #{access1}!" if access1.nil? || ![:register, :immediate].member?(access1)
    raise "unknown access2 #{access2}!" if !access2.nil? && ![:register, :immediate].member?(access2)
    raise "unknown op_type #{op_type}" unless [:numeric, :logical, :assignment].member?(op_type)
  end

  def store_result(before_state, op_input, value)
    after = before_state.clone
    after.set(op_input[3], value)
    after
  end

  def apply(before, op_input)
    raise "wrong input type" if before.class != Registerstate

    val1 = @access1 == :immediate ? op_input[1] : before.get(op_input[1])
    if @access2
      val2 = @access2 == :immediate ? op_input[2] : before.get(op_input[2])
    end
    
    res = nil
    case @op_type
    when :numeric
      res = val1.send(@operator, val2)
    when :logical
      res = val1.send(@operator, val2) == false ? 0 : 1
    when :assignment 
      res = val1
    else
      raise "unknown op type #{@op_type}"
    end

    store_result(before, op_input, res)
  end

  def self.operations
    @operations
  end

  def self.operation_for_name(name)
    @name_map ||= begin
      out = {}
      operations.each do |op|
        out[op.name] = op
      end
      out
    end
    @name_map[name]
  end

  def self.init_operations
    ops = []
    ops << Operation.new('addr', :register, :register, :+)
    ops << Operation.new('addi', :register, :immediate, :+)
    ops << Operation.new('mulr', :register, :register, :*)
    ops << Operation.new('muli', :register, :immediate, :*)
    ops << Operation.new('banr', :register, :register, :&)
    ops << Operation.new('bani', :register, :immediate, :&)
    ops << Operation.new('borr', :register, :register, :|)
    ops << Operation.new('bori', :register, :immediate, :|)
    ops << Operation.new('setr', :register, nil, nil, :assignment)
    ops << Operation.new('seti', :immediate, nil, nil, :assignment)
    ops << Operation.new('gtir', :immediate, :register, :>, :logical)
    ops << Operation.new('gtri', :register, :immediate, :>, :logical)
    ops << Operation.new('gtrr', :register, :register, :>, :logical)
    ops << Operation.new('eqir', :immediate, :register, :==, :logical)
    ops << Operation.new('eqri', :register, :immediate, :==, :logical)
    ops << Operation.new('eqrr', :register, :register, :==, :logical)
    ops
  end

  @operations = init_operations
end

class OpMatcher
  def initialize(test)
    @test = test
  end

  def matching_operations

  end
end

class OpTest

  def initialize(before, after = nil, input = nil)
    @before = before
    @after = after
    @input = input
  end

  def operation_id
    @input[0]
  end

  def add_input(input)
    @input = input
  end

  def add_after(after)
    @after = after
  end

  def matches?(operation)
    res = operation.apply(@before, @input)
    #puts "result #{res} vs predicted #{@after}"
    res == @after
  end

  def print
    puts "Before: #{@before}"
    puts @input.join(' ')
    puts "After: #{@after}"
  end
end

class OpPredictor

  def initialize
    @tests = []
    @current_test = nil
    @inputs = []
  end

  def match_line(line)
    if m = /Before:\s+\[(\d+), (\d+), (\d+), (\d+)\]/.match(line)
      {type: :before, value: Registerstate.new([m[1], m[2], m[3], m[4] ])}
    elsif m = /After:\s+\[(\d+), (\d+), (\d+), (\d+)\]/.match(line)
      {type: :after, value: Registerstate.new([m[1], m[2], m[3], m[4] ])}
    elsif m = /(\d+) (\d+) (\d+) (\d+)/.match(line)
      {type: :input, value: [m[1].to_i, m[2].to_i, m[3].to_i, m[4].to_i ]}
    elsif !line.empty?
      raise "unrecognizef format of #{line}"
    else
      nil
    end
  end


  def add_line(line)
    result = match_line(line)
    return unless result
    if result[:type] == :before
      raise "cannot have before after each other" unless @current_test.nil?
      @current_test = OpTest.new(result[:value])
    elsif result[:type] == :input
      if @current_test.nil?
        @inputs << result[:value]
      else
        @current_test.add_input(result[:value])
      end
    elsif result[:type] == :after
      raise "cannot have after state without before" if @current_test.nil?
      @current_test.add_after(result[:value])
      @tests << @current_test
      @current_test = nil
    end
  end

  def print_tests
    @tests.each do |test|
      test.print
      puts ""
    end
  end

  def calculate_matches
    matching_ops = Hash.new { |hash, key| hash[key] = [] }
    id_name_matches = Hash.new { |hash, key| hash[key] = Set.new }
    @tests.each_with_index do |op_test, row|
      puts "Test, op id is #{op_test.operation_id}"
      puts op_test.print
      Operation.operations.each do |op|
        #puts "operation '#{op.name}'"
        if op_test.matches?(op)
          id_name_matches[op_test.operation_id] << op.name
          matching_ops[row] << op.name
          puts "matches operation '#{op.name}'"
        end
      end
    end
    puts "id_name_matches count #{id_name_matches.size}"

    map = {}
    id_name_matches.each do |id, name_set|
      map[id] = name_set.to_a
    end
    {test_matches: matching_ops, id_name_matches: map}
  end

  def apply_operations(operation_map)
    state = Registerstate.new([0, 0, 0, 0])
    @inputs.each do |input|
      op_name = operation_map[input[0]]
      puts "op id #{input[0]} maps to #{op_name}"
      op = Operation.operation_for_name(op_name)
      state = op.apply(state, input)
    end
    puts "final state #{state}"
  end

end

class OperationResolver

  def initialize(id_name_matches)
    @id_name_matches = id_name_matches
    @id_name_mapping = {}
  end

  def get_unique_matches
    @id_name_matches.select do |id, names|
      names.size == 1
    end
  end

  def remove_from_ambiguous_list(id, name)
    @id_name_matches.delete(id)
    # remove the name from the ambiguous names list
    @id_name_matches.each do |_id, _names|
      _names.delete(name)
    end
    # remove empty parts
    @id_name_matches.delete_if do |_id, _names|
      _names.empty?
    end
  end

  def print_ambiguous_list
    puts "remaining ambiguous mappings"
    @id_name_matches.each do |id, names|
      puts "id #{id} matches operations #{names.join(', ')}"
    end
  end

  def add_to_mapping(unique_matches)
    unique_matches.each do |id, names|
      unique_name = names.first
      puts "direct mapping #{id} => #{unique_name}"
      @id_name_mapping[id] = unique_name
      remove_from_ambiguous_list(id, unique_name)
      #print_ambiguous_list
    end 
  end

  def resolve
    while !(un = get_unique_matches).empty?
      add_to_mapping(un)
    end
  end

  def resolved?
    @id_name_matches.empty?
  end

  def operation_map
    @id_name_mapping
  end
end

predictor = OpPredictor.new
if (ARGV[0] && File.exists?(ARGV[0]))
  File.open(ARGV[0]).each_line do |line|
    predictor.add_line(line.strip)
  end
else
  example = ['Before: [3, 2, 1, 1]', '[9 2 1 2]', 'After:  [3, 2, 2, 1]']
  example.each do |line|
    predictor.add_line(line)
  end
end
predictor.print_tests
match_data = predictor.calculate_matches
ambig = match_data[:test_matches].count do |row, names|
  names.size >= 3
end
puts "ambiguous (behave like 3 or more): #{ambig}"
match_data[:id_name_matches].each do |id, names|
  puts "id #{id} matches operations #{names.join(', ')}"
end
resolver = OperationResolver.new(match_data[:id_name_matches])
resolver.resolve
if resolver.resolved?
  puts "All operations matched!"
  predictor.apply_operations(resolver.operation_map)
else
  resolver.print_ambiguous_list
end