require 'json'
require './creds'

BookstoreCategories = ['4bf58dd8d48988d114951735','4bf58dd8d48988d1b1941735']

def bookstores_near(zip) # Zip -> Url
  "https://api.foursquare.com/v2/venues/search?near=#{zip.tr('^0-9','')}+usa&categoryId=#{BookstoreCategories.join(',')}&limit=50&client_id=#{ClientId}&client_secret=#{ClientSecret}&v=20200101"
end

def zip_prefixes_to_zipcodes(prefixes)
  prefixes.collect_concat {|pfx| (0..99).map {|i| "%05i".%(pfx * 100 + i) } }
end

Zip_prefixes_to_try = (ARGV[0].to_i..ARGV[1].to_i)

throw "zip codes not in use" if ARGV[1].to_i.zero?

def wget(url)
  sleep 1
  `wget -nv --output-document=- '#{url}'`
end

def venues(r) # :: 4SQResponse -> [Venue]
  JSON.parse(r)['response']['venues'] rescue []
end

def extract(v) # :: Venue -> Maybe (Id, Phone, Name)
  is_bookstore = !(v['categories'].map {|c| c['id'] } & BookstoreCategories).empty?
  return nil unless is_bookstore
  has_formattedPhone = v.has_key?('contact') && v['contact'].has_key?('formattedPhone')
  return nil unless has_formattedPhone
  [v['id'], v['contact']['formattedPhone'], v['name'], v['location']['postalCode'], v['location']['lat'].round(6), v['location']['lng'].round(6)]
end

puts zip_prefixes_to_zipcodes(Zip_prefixes_to_try).collect_concat {|z| venues(wget(bookstores_near(z))).map {|v| extract(v) }.compact }.uniq.sort.map {|v| v.join("\t") }.join("\n")
