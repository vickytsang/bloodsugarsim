#test for Session class
require_relative '../lib/session.rb'
require_relative '../lib/event.rb'

# spec/session.rb
describe Session do
    foodshash = Hash.new
    foodshash['1'] = 12
    foodshash['2'] = 45
    exercisehash = Hash.new
    exercisehash['1'] = 60
    exercisehash['2'] = 25
    eventhash = []
    t_event1 = Time.new('2018','12','23','12','12')
    t_event2 = Time.new('2018','12','23','16','12')
    eventhash << Event.new(:timestamp => t_event1,
                            :command => 'eat',
                            :index => foodshash['1'])
    eventhash << Event.new(:timestamp => t_event2,
                        :command => 'eat',
                        :index => foodshash['2'])

    session = Session.new(input: eventhash, foods: foodshash, exercises: exercisehash)
    describe ".initialize" do
      it "will initialize start and end time" do
        expect(session.t_zero).to eq(t_event1)
        expect(session.t_end).to eq(t_event2 + 3 * 60 * 60)
      end

      it "will initialize foods and exercise hash" do
        expect(session.inputhash.length).to eq(2)
        expect(session.foods.size).to eq(2)
        expect(session.exercises.size).to eq(2)
      end

      it "will initialize begin idle to session start time" do
        expect(session.begin_idle).to eq(t_event1 + 2 * 60 * 60)
      end

      it "will initialize blood sugar level to 80" do
        expect(session.blood_sugar).to eq(80)
      end

      it "will initialize glycation level to 0" do
        expect(session.glycation).to eq(0)
      end
    end

    describe "idle time" do
      it "will reset idle time if new idle timestamp is newer than current" do
        idle_time1 = Time.new('2018','12','22','16','12')
        idle_time2 = Time.new('2018','12','23','15','15')
        session.set_begin_idle(idle_time1)
        expect(session.begin_idle).to eq(t_event1 + 2 * 60 * 60)
        session.set_begin_idle(idle_time2)
        expect(session.begin_idle).to eq(idle_time2)
      end
    end

    describe "glycation" do
      it "will increment glycation by 1" do
        session.increment_glycation
        expect(session.glycation).to eq(1)
      end
    end

    describe "normalize" do
      it "will return true if timestamp is equal or past begin idle time" do
        idle_time = Time.new('2018','12','23','15','15')
        timestamp = Time.new('2018','12','23','15','15')
        session.set_begin_idle(idle_time)
        ret = session.normalize?(timestamp)
        expect(ret).to eq(true)
      end
    end

    describe "blood sugar" do
      it "will add pending blood sugar decrease event" do
        session.add_pending_blood_sugar_increases(-1, 60, t_event2)
        expect(session.num_pending_blood_sugar_incr).to eq(60)
        bs_events = session.pending_blood_sugar_events
        expect(bs_events[0][:timestamp]).to eq(t_event2 + 1 * 60)
        expect(bs_events[0][:bloodsugar]).to be_within(0.2).of(0-1/60)
        expect(bs_events[59][:timestamp]).to eq(t_event2 + 60 * 60)
        expect(bs_events[59][:bloodsugar]).to be_within(0.2).of(0-1/60)
      end

      it "will process and remove blood sugar event at timestamp" do
        (1..60).each do |t|
          session.process_pending_blood_sugar_increase(t_event2 + t * 60)
        end
        expect(session.blood_sugar).to be_within(0.2).of(80)
        bs_events = session.pending_blood_sugar_events
        expect(bs_events.length).to eq(0)
      end

      it "will add pending blood sugar increase event" do
        session.add_pending_blood_sugar_increases(foodshash['1'], 120, t_event1)
        expect(session.num_pending_blood_sugar_incr).to eq(120)
        bs_events = session.pending_blood_sugar_events
        expect(bs_events[0][:timestamp]).to eq(t_event1 + 1 * 60)
        expect(bs_events[0][:bloodsugar]).to be_within(0.2).of(12/120)
        expect(bs_events[119][:timestamp]).to eq(t_event1 + 120 * 60)
        expect(bs_events[119][:bloodsugar]).to be_within(0.2).of(12/120)
      end

    # it "will process and remove blood sugar event at timestamp" do
    #   (1..120).each do |t|
    #     session.process_pending_blood_sugar_increase(t_event1 + t * 60)
    #   end
    #   expect(session.blood_sugar).to be_within(0.2).of(92)
    #   bs_events = session.pending_blood_sugar_events
    #   expect(bs_events.length).to eq(0)
    # end
    end
  end