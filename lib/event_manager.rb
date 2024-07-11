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
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_numbers(num)
  only_num_strings = "0".upto("9")
  num_sliced = num.split("")

  num_sliced.select! do |ele|
    only_num_strings.include? ele
  end

  final_num = if !(num_sliced.size.between?(10,11))
                # Bad number: digits too short or too long
                "N/A"
              elsif num_sliced.size == 11 && num_sliced.first != "1"
                # Bad number: should start with 1 if more than 10 digits
                "N/A"
              elsif num_sliced.size == 11 && num_sliced.first == "1"
                # Good number, trim the 1 and use remaining 10 digitis
                num_sliced.delete_at(0)
                num_sliced.join
              elsif num_sliced.size == 10
                # Good number
                num_sliced.join
              else
                # Bad number: unknown reason
                "N/A"
              end

  final_num
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end

  puts "Saved thank you letter for user #{id}"
end

def generate_thank_you_letters(contents)
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter
  contents.each do |row|
    id = row[0]
    name = row[:first_name]#.ljust(15, ' ')
    zipcode = clean_zipcodes(row[:zipcode])#.ljust(10, ' ')
    home_phone = clean_phone_numbers(row[:homephone])#.ljust(15, ' ')

    legislators = legislators_by_zipcode(zipcode)

    # puts "Name: #{name} | Zip-code: #{zipcode} | Home Phone: #{home_phone}"

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
  end
end

puts "Generate Thank You Letters..."
generate_thank_you_letters(contents)
