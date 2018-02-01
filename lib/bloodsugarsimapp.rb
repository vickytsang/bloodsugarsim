require_relative 'parser.rb'
require_relative 'event_log.rb'
require_relative 'session.rb'

class BloodSugarSimApp
  def initialize
    @foodshash = Hash.new
    @exercisehash = Hash.new
    @eventhash = []
  end

  def run
    session = Session.new(input: @eventhash, foods: @foodshash, exercises: @exercisehash)
    session.run
  end

  def parse_csv file_path
    file_name = parse_filename(file_path)
    puts "parsing file #{file_path}"
    case file_name
    when 'foods.txt'
      parse_food(file_path)
    when 'exercise.txt'
      parse_exercise(file_path)
    when 'input.txt'
      parse_input(file_path)
    end
  end

  private
  def parse_filename file_path
    str = file_path.split('/')
    index = str.length - 1
    filename = str[index]
  end

  def parse_food file_name
    File.open(file_name).each do |line|
      parser = Parser.new(line)
      @foodshash[parser.id] = parser.index
    end
  end

  def parse_exercise file_name
    File.open(file_name).each do |line|
      parser = Parser.new(line)
      @exercisehash[parser.id] = parser.index
    end
  end

  def parse_input file_name
    File.open(file_name).each do |line|
      parser = Parser.new(line)
      ts_parser = TimeStampParser.new(:timestamp => parser.timestamp)
      @eventhash << Event.new(:timestamp => ts_parser.time,
                              :event => parser.event,
                              :event_id => parser.event_id,
                              :event_index => event_index(parser.event, parser.event_id))
    end
  end

  private
  def event_index(event, id)
    index = 0
    case event
    when 'eat'
      index = @foodshash[id]
      return index
    when 'exercise'
      index = @exercisehash[id]
      return index
    end
    raise "Event index for #{event}=#{id} not found!!!!"
    index
  end
end