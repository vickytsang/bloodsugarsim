class TimeStampParser
  def initialize params = {}
  ##
  # @timestamp: "2018-01-01 08:00"
  # "@date: "2018-01-01"
  # "@time: "08:00"
    @timestamp = params[:timestamp] || ''
    if @timestamp == ''
      @date = params[:date] || ''
      @time = params[:time] || ''
    else
      ts = @timestamp.split(' ')
      @date = ts[0]
      @time = ts[1]
    end
  end

  def year
    date = @date.split('-')
    date[0]
  end

  def month
    date = @date.split('-')
    date[1]
  end

  def day
    date = @date.split('-')
    date[2]
  end

  def hour
    time = @time.split(':')
    time[0]
  end

  def minute
    time = @time.split(':')
    time[1]
  end

  def time
    Time.new(year, month, day, hour, minute)
  end
end

class Parser
  attr_reader :line, :params
  def initialize(line)
    @line = line
    @params = line.split(' ') || []
  end

  def id
    @params[0]
  end

  def index
    @params[1].to_i
  end

  def event
    @params[2].downcase
  end

  def event_id
    @params[3]
  end

  def timestamp
    @params[0] + ' ' + @params[1]
  end
end