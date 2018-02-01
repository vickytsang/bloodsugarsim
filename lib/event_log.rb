class EventLog
  attr_reader :timestamp, :bloodsugar, :glycation
  def initialize params = {}
    @event = params[:event]
    @foodhash = params[:food] || nil
    @exercisehash = params[:exercise] || nil
    @bloodsugar = params[:bloodsugar] || nil
    @glycation = params[:glycation] || nil
    @timestamp = params[:timestamp]
  end

  def date
    @timestamp.year.to_s + '-' + @timestamp.month.to_s + '-' + @timestamp.day.to_s
  end

  def time
    @timestamp.hour.to_s + ':' + @timestamp.min.to_s
  end
end