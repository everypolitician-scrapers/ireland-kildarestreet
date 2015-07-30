#!/bin/env ruby
# encoding: utf-8

require 'colorize'
require 'csv'
require 'json'
require 'nokogiri'
require 'scraperwiki'

require 'pry'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def reprocess_csv(file)
  csv = CSV.table(open(file))
  csv.map do |td|
    td[:id]        = (td.delete :person_id).last
    td[:source]    = (td.delete :uri).last
    td[:sort_name] = "%s, %s" % [td[:last_name], td[:first_name]]
    td[:term]      = '31'
    td.to_hash
  end
end

def scrape_list(url)
  noko = noko_for(url)
  table = noko.css('table.people')
  noko.xpath('.//tr[td]').map do |tr|
    tds = tr.css('td')
    data = {
      image: tds[0].css('img/@src').text,
      name: tds[1].css('a').text,
      party_id: tds[2].text,
      constituency: tds[3].text,
    }
    data[:id] = data[:image][/(\d+).(jpg|png)$/, 1]
    data[:image] = URI.join(url, data[:image]).to_s.sub('/images/','/images/mpsL/') unless data[:image].to_s.empty?
    data
  end
end

csv_data = reprocess_csv('https://www.kildarestreet.com/tds/?f=csv')
web_data = scrape_list('https://www.kildarestreet.com/tds/')

csv_data.each do |csv_row|
  web_row = web_data.find { |r| r[:id].to_s == csv_row[:id].to_s } or binding.pry
     # raise "No web match for #{csv_row[:id]}: #{csv_row[:sort_name]}"
  data = csv_row.merge(web_row)
  ScraperWiki.save_sqlite([:id, :term], data)
end

