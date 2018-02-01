#test for Parser class
require_relative '../lib/parser.rb'

# spec/parser.rb
describe TimeStampParser do
  describe ".initialize" do
    it "will initialize with date and time string" do
      ts = TimeStampParser.new(date: "2018-12-04", time: "08:40")
      expect(ts.year).to eq("2018")
      expect(ts.month).to eq("12")
      expect(ts.day).to eq("04")
      expect(ts.hour).to eq("08")
      expect(ts.minute).to eq("40")
    end
    it "will initialize with date and time string" do
      ts = TimeStampParser.new(timestamp: "2018-12-04 08:40")
      expect(ts.year).to eq("2018")
      expect(ts.month).to eq("12")
      expect(ts.day).to eq("04")
      expect(ts.hour).to eq("08")
      expect(ts.minute).to eq("40")
    end
  end

  describe "Time" do
    it "will reture time" do
      ts1 = TimeStampParser.new(timestamp: "2018-12-04 08:40")
      t = Time.new(ts1.year,
        ts1.month,
        ts1.day,
        ts1.hour,
        ts1.minute)
      expect(ts1.time).to eq(t)
    end
  end
end

describe Parser do
  describe ".initialize" do
    it "will initialize an input line" do
      parser = Parser.new('2018-01-01 18:00 EAT 120')
      expect(parser.line).to eq('2018-01-01 18:00 EAT 120')
      expect(parser.params[0]).to eq('2018-01-01')
      expect(parser.params[1]).to eq('18:00')
      expect(parser.params[2]).to eq('EAT')
      expect(parser.params[3]).to eq('120')
    end

    it "will initialize food/exercise id with indices" do
      parser = Parser.new('1 47')
      expect(parser.line).to eq('1 47')
      expect(parser.params[0]).to eq('1')
      expect(parser.params[1]).to eq('47')
    end
  end
end