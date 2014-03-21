#!/usr/bin/env ruby

require 'watir-webdriver'
require 'mongo'

include Mongo

SURFSPOTS = []

def check_time(early_hour, early_minute, late_hour, late_minute, t=Time.now)
  early = Time.new(t.year, t.month, t.day, early_hour, early_minute, 0, t.utc_offset)
  late  = Time.new(t.year, t.month, t.day, late_hour, late_minute, 0, t.utc_offset)
  puts "early: " + early.to_s + ", late: " + late.to_s + ", current: " + t.to_s
  t.between?(early, late)
end


def get_info_for_spot(br, name, url)
  puts url+"\n"
  br.goto(url)

  time = Time.new
  puts time.to_s
  puts time.ctime
  puts time.localtime
  puts time.strftime("%Y-%m-%d %H:%M:%S")
  time_string =  time.strftime("%Y-%m-%d %H:%M:%S")
  time_string =  time.strftime("%H:%M:%S")
  date_string =  time.strftime("%Y-%m-%d")

#When(/^the most recent report was posted within the last hour$/) do
  sleep(1)
  puts "\n"


  tide = br.div(:class => 'livetide')
  tide = tide.span.text
  #puts "tide: " + tide
  #puts "\n"

  swell = br.spans(:id => /current-surf-period*/)
  swells = ""
  for s in swell
    swells += " ; " + s.text
  end
  swell = swells

  wind = br.div(:id => 'curr-wind-div')
  wind = wind.text

  report_range = br.h2(:id => 'observed-wave-range')
  report_range = report_range.text

  report_conditions = br.div(:id => 'observed-spot-conditions')
  report_conditions = report_conditions.text

  report_text = br.div(:id => 'observed-spot-conditions-summary')
  report_text = report_text.text


  spot =  {'name'=> name, 'time' => time_string, 'date'=> date_string, 'tide'=>tide, 'swells'=>swell, 'wind'=>wind, 'report_range'=>report_range, 'report_conditions'=>report_conditions, 'report_text'=>report_text}



  SURFSPOTS << spot
end


def scrape_pages()

  br = Watir::Browser.new :chrome

  pages = [
    ["Scripps", "http://www.surfline.com/surf-report/scripps-southern-california_4246/"],
    ["Pacific Beach", "http://www.surfline.com/surf-report/pacific-beach-southern-california_4250/"],
    ["Tourmaline", "http://www.surfline.com/surf-report/old-mans-tourmaline-southern-california_4804/"],
    ["Mission Beach", "http://www.surfline.com/surf-report/mission-beach-southern-california_4252/"],
    ["Del Mar", "http://www.surfline.com/surf-report/del-mar-southern-california_4783/"],
    ["Cardiff", "http://www.surfline.com/surf-report/cardiff-southern-california_4786/"],
    ["Tamarack", "http://www.surfline.com/surf-report/tamarack-southern-california_4242/"]
  ]

  for page in pages
    puts page[0]

    get_info_for_spot(br, page[0], page[1])

  end

  puts SURFSPOTS.length

  br.close()

  client = MongoClient.new
  db = client['test-db']


  for spot in SURFSPOTS
    coll = db[spot['name']]
    puts "#{spot['name']}"
    puts spot['time']
    puts spot['date']
    puts spot['tide']
    puts spot['swells']
    puts spot['wind']
    puts spot['report_range']
    puts spot['report_conditions']
    puts spot['report_text']
    coll.insert(spot)
    puts "\n"
  end

end





while true
  if  check_time(7, 45, 7, 55)
    scrape_pages()
  elsif check_time(2, 15, 2, 25)
    scrape_pages()
  else
    puts "not running"
  end

  sleep(10*60)

end










