require 'csv'

puts "Event Manager Initialized!"

small_attendees_file = "./event_attendees.csv"
puts "Does small sample data file exist: #{File.exist? small_attendees_file}\n\n"


contents = CSV.open(
  small_attendees_file,
  headers: true,
  header_converters: :symbol
)

def clean_zipcodes(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

contents.each do |row|
  name = row[:first_name].ljust(15, ' ')
  zipcode = clean_zipcodes(row[:zipcode])

  puts "Name: #{name} | Zip-code: #{zipcode}"
end
