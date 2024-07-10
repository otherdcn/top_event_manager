require 'csv'
require 'google/apis/civicinfo_v2'

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

def legislators_by_zipcode(zipcode)
 civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
 civic_info.key = File.read('secret.key').strip

 begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )

    legislators = legislators.officials

    legislator_names = legislators.map(&:name)

    legislator_names.join(", ")
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

contents.each do |row|
  name = row[:first_name].ljust(15, ' ')
  zipcode = clean_zipcodes(row[:zipcode]).ljust(10, ' ')

  legislators = legislators_by_zipcode(zipcode)

  puts "Name: #{name} | Zip-code: #{zipcode} | #{legislators}"
end
