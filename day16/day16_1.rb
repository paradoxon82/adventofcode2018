#!/usr/bin/ruby

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

  def matching_operations
    matching_ops = Hash.new { |hash, key| hash[key] = [] }
    @tests.each_with_index do |op_test, row|
      puts "Test"
      puts op_test.print
      Operation.operations.each do |op|
        #puts "operation '#{op.name}'"
        if op_test.matches?(op)
          matching_ops[row] << op.name
          puts "matches operation '#{op.name}'"
        end
      end
    end
    matching_ops
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
matching = predictor.matching_operations
ambig = matching.count do |row, names|
  names.size >= 3
end
puts "ambiguous (behave like 3 or more): #{ambig}"
