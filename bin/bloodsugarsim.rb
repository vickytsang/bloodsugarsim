require 'io/console'
require_relative '../lib/bloodsugarsimapp.rb'

if ARGV.length > 0
  myApp = BloodSugarSimApp.new
  for i in 0 ... ARGV.length
    file_name = ARGV[i]
    puts "*******input file #{file_name}"
    myApp.parse_csv(file_name)
  end
  myApp.run

  done = STDIN.getch
end
