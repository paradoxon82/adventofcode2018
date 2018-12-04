#!/usr/bin/ruby

require 'date'

class Test

  def example
    '[1518-11-01 00:00] Guard #10 begins shift
[1518-11-01 00:05] falls asleep
[1518-11-01 00:25] wakes up
[1518-11-01 00:30] falls asleep
[1518-11-01 00:55] wakes up
[1518-11-01 23:58] Guard #99 begins shift
[1518-11-02 00:40] falls asleep
[1518-11-02 00:50] wakes up
[1518-11-03 00:05] Guard #10 begins shift
[1518-11-03 00:24] falls asleep
[1518-11-03 00:29] wakes up
[1518-11-04 00:02] Guard #99 begins shift
[1518-11-04 00:36] falls asleep
[1518-11-04 00:46] wakes up
[1518-11-05 00:03] Guard #99 begins shift
[1518-11-05 00:45] falls asleep
[1518-11-05 00:55] wakes up'
  end

end

class GuardShift
  attr_reader :guard_id, :times_asleep

  def initialize(guard_id, date, begin_hour, begin_minute)
    @guard_id = guard_id
    @shift_date = date
    @begin_hour = begin_hour
    @begin_minute = begin_minute
    @times_asleep = []
  end

  def sleep_range(last_sleep, wake_up)
    if last_sleep < wake_up
      (last_sleep...wake_up).to_a
    else
      raise "last_sleep #{@last_sleep} is not before wake up #{wake_up}"
    end      
  end

  def wake_up_event(minute)
    if @last_sleep
      @times_asleep.concat(sleep_range(@last_sleep, minute))
      #puts "#{@times_asleep}"
      @last_sleep = nil
    else
      raise "no sleep event recorded for wake event at #{minute}"
    end
  end

  def sleep_event(minute)
    @last_sleep = minute
  end

  def minutes_asleep
    @times_asleep.size
  end

end

GuardEvent = Struct.new(:date, :hour, :minute, :type, :guard_id)

class GuardObserver

  def initialize()
    # to sort by timestamp
    @lines = {}
    @guard_shifts = []
  end

  # 
  def match_line(line)
    /\[(?<timestamp>[^\]]+)\] (?<description>.+)/.match(line.strip)
  end

  def parse_description(desc)
    if m = /Guard #(?<guard_id>\d+) begins shift/.match(desc)
      {guard_id: m[:guard_id].to_i, type: :shift_begin}
    elsif desc == 'falls asleep'
      {type: :sleep}
    elsif desc == 'wakes up'
      {type: :wake_up}
    else
      raise "unrecognized description #{desc}"
    end
  end

  def build_event(m)
    timestamp = DateTime.parse(m[:timestamp])
    desc = parse_description(m[:description])
    GuardEvent.new(timestamp.to_date, timestamp.hour, timestamp.minute, desc[:type], desc[:guard_id])
  end

  def parse_line(line)
    if m = match_line(line)
      build_event(m)
    else
      nil
    end
  end

  # assumes the events are coming in ordered by date
  def register_event(event)
    case event.type
    when :shift_begin
      @guard_shifts << GuardShift.new(event.guard_id, event.date, event.hour, event.minute)
    when :sleep
      @guard_shifts.last.sleep_event(event.minute)
    when :wake_up
      @guard_shifts.last.wake_up_event(event.minute)
    else
      raise "unrecognized event type #{event.type}"
    end
  end

  def add_line(line)
    m = match_line(line)
    if m
      @lines[DateTime.parse(m[:timestamp])] = line
    else
      raise "unable to parse line #{line}"
    end
  end

  def register_lines
    @lines.sort_by { |timestamp, line| timestamp}.each do |timestamp, line|
      register_event(parse_line(line))
    end
  end

  # guard with the most sleeping minutes
  def sleepiest_guard
    guards_minutes = Hash.new { |hash, key| hash[key] = 0 }
    guards_times = Hash.new { |hash, key| hash[key] = [] }
    @guard_shifts.each do |shift|
      guards_minutes[shift.guard_id] += shift.minutes_asleep
      guards_times[shift.guard_id].concat(shift.times_asleep)
    end
    sleepiest_guard, minutes_asleep = guards_minutes.max_by do |guard_id, minutes|
      minutes
    end
    min_map = guards_times[sleepiest_guard].group_by { |minutes| minutes }
    min, min_list = min_map.max_by { |min, min_list| min_list.size}

    answer = min * sleepiest_guard
    return {guard_id: sleepiest_guard, minutes: minutes_asleep, most_often_asleep_at: min, times: min_list.size, answer: answer}
  end

  # guard most often asleep at the same minute
  def sleepiest_guard2
    minutes_maps = Hash.new { |hash, key| hash[key] =  0 } 
    @guard_shifts.each do |shift|
      shift.times_asleep.each do |minute|
        minutes_maps[{guard_id: shift.guard_id, minute: minute}] += 1
      end
    end

    key, max_count = minutes_maps.max_by {|key, count| count}
    answer = key[:minute] * key[:guard_id]
    return {guard_id: key[:guard_id], minutes: 0, most_often_asleep_at: key[:minute], times: max_count, answer: answer}
  end

end

checker = GuardObserver.new
File.open(ARGV[0]).each_line do |line|
  checker.add_line(line)
end
checker.register_lines
result = checker.sleepiest_guard
puts "case1:"
puts "sleepiest guard: id #{result[:guard_id]} is asleep #{result[:minutes]} minutes"
puts "mostly at #{result[:most_often_asleep_at]}, exactly #{result[:times]} times"

puts "answer is: #{result[:answer]}"

result = checker.sleepiest_guard2

puts "case2:"
puts "sleepiest guard: id #{result[:guard_id]} is asleep #{result[:minutes]} minutes"
puts "mostly at #{result[:most_often_asleep_at]}, exactly #{result[:times]} times"

puts "answer is: #{result[:answer]}"