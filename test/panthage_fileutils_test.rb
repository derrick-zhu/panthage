require 'test/unit'
require_relative '../tools/extensions/fileutils_ext'

class FileUtilsTest < Test::Unit::TestCase
  def setup
    # Do nothing
    @base_dir = "."
    @file_to_find = "Panda.xcodeproj"
  end

  def teardown
    # Do nothing
  end

  def test_find_file_in_path
    result = FileUtils.find_path_in_r(@file_to_find, @base_dir)
    puts result.to_s

    assert(result.nil? == false && result.empty? == false)
  end

  def test_find_file_in_path_exclude
    Dir.chdir(@base_dir)
    result = FileUtils.find_path_in_r(@file_to_find, @base_dir, 'demo/')
    puts result.to_s
    assert(result.nil? == false && result.empty? == false)
  end
end