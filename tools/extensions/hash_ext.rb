#!/usr/bin/ruby
#
class Hash
  def to_xc_s(join_str = ' ')
    compact.each_with_object([]) do | (key,value), result|
      result.push([key, value].join(join_str))
    end.join(' ')
  end
end
