#!/usr/bin/ruby

require 'json'
require 'crack'

module XMLUtils
  def to_json(xml)
    Crack::XML.parse(xml).to_json
  end
end
