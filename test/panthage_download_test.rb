#!/usr/bin/ruby
# frozen_string_literal: true

require 'test/unit'
require_relative '../tools/panthage_dependency'
require_relative '../tools/panthage_cartfile_model'
require_relative '../tools/panthage_downloader'

class MyTest < Test::Unit::TestCase
  attr_reader :json_url

  def setup
    @json_url = 'https://raw.githubusercontent.com/AppsFlyerSDK/AppsFlyerFramework/master/AppsFlyerTracker.json'
    @target_version = '4.9.0'
    @target_file = 'AppsFlyerTracker.framework.zip'
    # @json_url = 'https://downloads.localytics.com/SDKs/iOS/Localytics.json'
    # @target_file = './Localytics-iOS-5.4.0.zip'
  end

  def teardown
    # Do nothing
  end

  def test_download

    cart_bin = CartFileBinary.new('main', 'minor', json_url, @target_version, '==')
    BinaryDownloader.check_prepare_binary(cart_bin)
    BinaryDownloader.download_binary_file(cart_bin.url, cart_bin.hash, '')
    BinaryDownloader.unzip(@target_file, 'AppsFlyerTracker.framework', './')
    assert(File.exist?(@target_file))
  end
end
