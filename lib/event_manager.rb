require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

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
    ).officials

    #legislators = legislators.officials
    #legislator_names = legislators.map(&:name)
    #legislator_names.join(", ")
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end

  puts "Saved thank you letter for user #{id}"
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]#.ljust(15, ' ')
  zipcode = clean_zipcodes(row[:zipcode])#.ljust(10, ' ')

  legislators = legislators_by_zipcode(zipcode)

  #puts "Name: #{name} | Zip-code: #{zipcode} | #{legislators}"

  #personal_letter = template_letter.gsub('FIRST_NAME', name)
  #personal_letter.gsub!('LEGISLATORS', legislators)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
