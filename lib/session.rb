require 'csv'
require_relative 'event_log.rb'
require_relative 'event.rb'

class Session
  attr_reader :t_zero, :t_end, :begin_idle, :inputhash, :foods, :exercises, :blood_sugar, :glycation
  EVENTMAP = {
    :eat => 'EAT',
    :exercise => 'EXERCISE',
    :glycation => 'GLYCATION',
    :blood_sugar => 'BlOOD_SUGAR',
  }

  def initialize params = []
    @t_zero = 0
    @t_end = 0

    @inputhash = params[:input]
    set_start_time(@inputhash.first.hash[:timestamp])
    set_end_time(@inputhash.last.hash[:timestamp] + 3 * 60 * 60)

    @eventlog = []
    @glycation_events = []
    @blood_sugar_events = []
    @glycation = 0
    @blood_sugar = 80
    @foods = params[:foods]
    @exercises = params[:exercises]
    @pending_blood_sugar_incr = []
    @begin_idle = @t_zero + 2 * 60 * 60
  end


##
# every minute
  def run
    idx = 0
    event = @inputhash[idx]
    session_duration = ((@t_end - @t_zero)/60).to_i
    puts ">>>>session total duration is #{session_duration} minutes"
    (0...session_duration).each do |m|
      ## log blood sugar and glycation on every minute
      log_time = @t_zero + m * 60
      puts ">>>>Log Time<<<<< #{log_time} blood sugar = #{@blood_sugar} glycation = #{@glycation}"

      process_pending_blood_sugar_increase(log_time)
      increment_glycation if glycation?
      normalize_blood_sugar(log_time) if normalize?(log_time)

      while process_event(event, @t_zero + m * 60)
        idx = idx + 1
        if idx < @inputhash.length
          event = @inputhash[idx]
        else
          break
        end
      end

      # log blood sugar level
      s_log = EventLog.new(:event => EVENTMAP[:blood_sugar],
                  :bloodsugar => @blood_sugar,
                  :timestamp => log_time)

      # puts "ssssss #{s_log}"
      @blood_sugar_events << s_log

      # log blood sugar level
      g_log = EventLog.new(:event => EVENTMAP[:glycation],
                      :glycation => @glycation,
                      :timestamp => log_time)

      # puts "gggggg #{g_log}"
      @glycation_events << g_log
    end

    log_bloodsugar(@blood_sugar_events)
    log_glycation(@glycation_events)
  end

  def process_event event, ts
    if event.hash[:timestamp] == ts
      ## there is an event at this time
      case event.hash[:event]
      when 'eat'
        return consume_food(event.hash[:event_id], event.hash[:timestamp], ts)
      when 'exercise'
        return do_exercise(event.hash[:event_id], event.hash[:timestamp], ts)
      end
    end
    return false
  end

  def consume_food id, ts, log_time
    puts "***EAT EVENT**** #{ts}"
    set_begin_idle(ts + 2 * 60 * 60)
    index = @foods[id].to_f
    add_pending_blood_sugar_increases(index.to_f, 120, ts)
    log = EventLog.new(:event => EVENTMAP[:eat],
                        :food_index => index,
                        :bloodsugar => @blood_sugar,
                        :glycation => @glycation,
                        :timestamp => log_time)
    @eventlog << log
    true
  end

  def do_exercise id, ts, log_time
    puts "***EXERCISE EVENT**** #{ts}"
    index = @exercises[id].to_f
    set_begin_idle(ts + 1 * 60 * 60)
    add_pending_blood_sugar_increases(-index, 60, ts)
    log = EventLog.new(:event => EVENTMAP[:exercise],
                        :excercise_index => index,
                        :bloodsugar => @blood_sugar,
                        :glycation => @glycation,
                        :timestamp => log_time)
    @eventlog << log
    true
  end


  def log_bloodsugar event_log
    CSV.open('bloodsugar_log.csv', 'w') do |csv|
      csv << ['date', 'time' 'blood sugar']
      event_log.each do |log|
        csv << [log.date, log.time, log.bloodsugar]
      end
    end
  end

  def log_glycation event_log
    CSV.open('glycation_log.csv', 'w') do |csv|
      csv << ['date', 'time', 'glycation']
      event_log.each do |log|
        csv << [log.date, log.time, log.glycation]
      end
    end
  end

  ##
  # @t_zero is the session start time
  def set_start_time ts
    @t_zero = ts
  end

  ##
  # @t_end is 3 hours after the last food or exercise event
  def set_end_time ts
    @t_end = ts
  end

  ##
  # @begin_idle is when blood sugar is expected to begin to normalize
  def set_begin_idle time
    if time > @begin_idle
      @begin_idle = time
    end
    puts "xxxxxxxxx begin idle at #{@begin_idle}"
    @begin_idle
  end

  def increment_glycation
    @glycation = @glycation + 1
  end

  ##
  # If neither food nor exercise is affecting your blood sugar
  # (it has been more than 1 or 2 hours), it will approach 80
  # linearly at a rate of 1 per minute.
  def normalize? ts
    @begin_idle == ts
  end

  def normalize_blood_sugar ts
    if @blood_sugar >= 80
      update_blood_sugar(-1, ts)
    end
  end

  ##
  # eating food will increase blood sugar linearly for two hours
  def add_pending_blood_sugar_increases index, duration, ts
    hourly_sugar_incr = (index.to_f / duration)
    (1..duration).each do |n|
      timestamp = ts + n * 60
      # puts "++++++++ BS #{timestamp} +#{hourly_sugar_incr}"
      @pending_blood_sugar_incr << { :timestamp => timestamp, :bloodsugar => hourly_sugar_incr }
    end
  end

  ##
  # process all blood sugar updates at this timestamp
  # pop all processed updates from the pending list
  def process_pending_blood_sugar_increase ts
    processed = []
    @pending_blood_sugar_incr.each do |bsi|
      if bsi[:timestamp] == ts
        puts "processing BS #{bsi[:timestamp]} @#{bsi[:bloodsugar]}"
        processed << bsi[:timestamp]
        update_blood_sugar(bsi[:bloodsugar], ts)
      end
    end

    processed.each do |p|
      length = @pending_blood_sugar_incr.length
      @pending_blood_sugar_incr.delete_if { |x| x[:timestamp] == p }
      if @pending_blood_sugar_incr.length < length
        # puts "popped #{p} #{length}"
      end
    end
  end

  def update_blood_sugar index, ts
    @blood_sugar = @blood_sugar + index
    if @blood_sugar < 80
      @blood_sugar = 80
    else
      @last_blood_sugar_event = ts
    end
    # puts "-------updated #{@blood_sugar} + #{index}"
  end

  ##
  # For every minute your blood sugar stays above 150,
  # increment “glycation” by 1.
  def glycation?
    @blood_sugar > 150
  end

  ################
  # for spec tests
  def num_pending_blood_sugar_incr
    @pending_blood_sugar_incr.length
  end

  def pending_blood_sugar_events
    @pending_blood_sugar_incr
  end
end
