#!/bin/env ruby
# encoding: utf-8

require 'colorize'
require 'csv'
require 'json'
require 'scraperwiki'

require 'pry'

def reprocess(file)
  csv = CSV.table(open(file))
  csv.each do |td|
    td[:id]        = (td.delete :person_id).last
    td[:source]    = (td.delete :uri).last
    td[:name]      = "%s %s" % [td[:first_name], td[:last_name]]
    td[:sort_name] = "%s, %s" % [td[:last_name], td[:first_name]]
    td[:term]      = '31'
    ScraperWiki.save_sqlite([:id, :term], td)
  end
end

reprocess('https://www.kildarestreet.com/tds/?f=csv')

