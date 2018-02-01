class Event
  attr_reader :hash
  def initialize params = {}
    @hash = Hash.new
    @hash[:timestamp] = params[:timestamp]
    @hash[:event_id] = params[:event_id]
    @hash[:event_index] = params[:event_index]
    @hash[:event] = params[:event]
  end
end