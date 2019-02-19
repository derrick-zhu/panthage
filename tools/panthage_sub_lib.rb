#!/usr/bin/ruby
# frozen_string_literal: true

require_relative 'panthage_cartfile_model'

def read_sub_lib_cartfile(lib_name, _base_dir, cartfile_file)
  cartfile = read_cart_file(lib_name.to_s, cartfile_file.to_s)
  cartfile.merge!(cartfile, read_cart_file(lib_name.to_s, cartfile_file.to_s + '.private'))

  cartfile
end
