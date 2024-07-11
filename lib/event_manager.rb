require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'colorize'

puts "Event Manager Initialized!"

def contents
  small_attendees_file = "./event_attendees.csv"

  contents = CSV.open(
    small_attendees_file,
    headers: true,
    header_converters: :symbol
  )
end

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

def registration_dates_n_times(contents)
  all_registration_dates_n_times = []

  contents.each do |row|
    date_n_time = row[:regdate]

    date, time = date_n_time.split

    month, day, year = date.split("/")
    hour, minute = time.split(":")

    full_year = if year.size == 2
                  year.rjust(4,"20")
                elsif year.size == 4
                  year
                else
                  "N/A"
                end

    registered = Time.mktime(full_year,month,day,hour,minute,0)

    all_registration_dates_n_times << registered
  end

  all_registration_dates_n_times
end

def peak_registration_hours(all_registration_dates_n_times)
   hours = Hash.new(0)

  all_registration_dates_n_times.each do |reg|
    hours[reg.hour] += 1
  end

  hours = hours.sort_by { |hour, frequency| -frequency }.to_h

  puts "Hour".ljust(7, " ").underline + "Frequency".underline
  hours.each do |hour, frequency|
    puts "#{hour.to_s.ljust(5," ")} | #{frequency}"
  end

  peak_hour, frequency = hours.max_by { |hour, frequency| frequency }

  puts "==> The Best hour to advertise is #{peak_hour}, with #{frequency} registrations during that time.\n\n"
end

def peak_registration_days(all_registration_dates_n_times)
  days_of_the_week = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  days = Hash.new(0)

  all_registration_dates_n_times.each do |reg|
    days[days_of_the_week[reg.wday]] += 1
  end

  days = days.sort_by { |day, frequency| -frequency }.to_h

  puts "Day".ljust(12," ").underline + "Frequency".underline
  days.each do |day, frequency|
    puts "#{day.ljust(10, " ")} | #{frequency}"
  end

  peak_day, frequency = days.max_by { |day, frequency| frequency }

  puts "==> The Best day to advertise is #{peak_day}, with #{frequency} registrations during that time.\n\n"
end

puts "===> Generate Thank You Letters..."
generate_thank_you_letters(contents)

puts "===> Best Time and Day to Advertise..."

all_registration_dates_n_times = registration_dates_n_times(contents)
peak_registration_hours(all_registration_dates_n_times)
peak_registration_days(all_registration_dates_n_times)
