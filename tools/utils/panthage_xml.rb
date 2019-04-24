#!/usr/bin/ruby

require 'json'
require 'crack'

class XMLUtils
  def self.to_json(xml)
    json_data = Crack::XML.parse(xml).to_json
    scheme_data = JSON.parse(json_data)

    scheme_data
  end
end
