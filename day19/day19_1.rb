#!/usr/bin/ruby

require 'set'

$verbose = true

class Registerstate
  attr_reader :state
  @size = 6
  class << self; attr_accessor :size end

  def initialize(state)
    @state = state.map(&:to_i)
    raise "Illegal state length" if state.size != Registerstate.size
  end

  def get(pos)
    if pos >= 0 && pos < Registerstate.size
      @state[pos]
    else
      raise "Illegal access to pos #{pos}"
    end
  end

  def set(pos, val)
    if pos >= 0 && pos < Registerstate.size
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
    after.set(op_input[2], value)
    #puts "setting register #{op_input[2]} to #{value}, result #{after}"
    # if op_input[2] == 0
    #   puts "name #{name}, input #{op_input}, before #{before_state}, after #{after}"
    #   puts "jump from line #{before_state.get(0)} to line #{after.get(0)}"
    # end
    after
  end

  def apply(before, op_input)
    raise "wrong input type" if before.class != Registerstate

    val1 = @access1 == :immediate ? op_input[0] : before.get(op_input[0])
    if @access2
      val2 = @access2 == :immediate ? op_input[1] : before.get(op_input[1])
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

class Instruction
  def initialize(operation_name, input)
    @operation = Operation.operation_for_name(operation_name)
    raise "unknown operation #{operation_name}" unless @operation
    @input = input
  end

  def apply(ip, state, ip_bind)
    state.set(ip_bind, ip)
    new_state = @operation.apply(state, @input)
    ip = new_state.get(ip_bind)
    return [ip, new_state]
  end

  def to_s
    "#{@operation.name} #{@input.join(' ')}"
  end
end

class OpPredictor

  def initialize
    @instructions = []
    @ip = nil
    @ip_bind = nil
  end

  def match_line(line)
    if m = /(\w+)\s+(\d+) (\d+) (\d+)/.match(line)
      {type: :instruction, value: Instruction.new(m[1], [m[2].to_i, m[3].to_i, m[4].to_i])}
    elsif m = /#ip (\d+)/.match(line)
      {type: :ip, value: m[1].to_i}
    elsif !line.empty?
      raise "unrecognizef format of #{line}"
    else
      nil
    end
  end


  def add_line(line)
    result = match_line(line)
    return unless result
    if result[:type] == :instruction
      @instructions << result[:value]
    elsif result[:type] == :ip
      @ip_bind = result[:value]
    end
  end

  def instruction_at(ip_pos)
    if ip_pos >= 0 && ip_pos < @instructions.size
      @instructions[ip_pos]
    else
      nil
    end
  end

  def apply_operations(initial_state = nil)
    @ip = 0
    state = nil
    if initial_state
      state = Registerstate.new(initial_state)
    else
      state = Registerstate.new([0, 0, 0, 0, 0, 0])
    end
    while (inst = instruction_at(@ip))
      #puts inst
      before = state.clone
      @ip, state = inst.apply(@ip, state, @ip_bind)
      if before.get(0) != state.get(0)
        puts "ip: #{@ip}, state #{state} from #{before}" if $verbose
      end
      @ip += 1
    end
    puts "ip: #{@ip}, final state #{state}"
  end

end

predictor = OpPredictor.new
if (ARGV[0] && File.exists?(ARGV[0]))
  File.open(ARGV[0]).each_line do |line|
    predictor.add_line(line.strip)
  end
  puts "part 1"
  #predictor.apply_operations
  puts "part 2"
  predictor.apply_operations([1, 0, 0, 0, 0, 0])
else
  example = ['#ip 0',
    'seti 5 0 1',
    'seti 6 0 2',
    'addi 0 1 0',
    'addr 1 2 3',
    'setr 1 0 0',
    'seti 8 0 4',
    'seti 9 0 5']
  example.each do |line|
    predictor.add_line(line)
  end
  predictor.apply_operations
end
