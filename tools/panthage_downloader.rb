#!/usr/bin/ruby
# frozen_string_literal: true

require 'rubygems'
require 'zip'
require 'down'
require 'json'
require_relative 'extensions/string_ext'
require_relative 'panthage_ver_helper'

class BinaryDownloader
  def self.check_prepare_binary(lib_data)
    info_file = Down.download(lib_data.url)
    info_raw = info_file.read
    info_data = JSON.parse(info_raw.encode('utf-8'))

    binary_list = VersionHelper.find_fit_version(info_data.keys, lib_data.version, lib_data.operator)
    raise "could not find #{lib_data.version} in '#{binary_list}.'" if binary_list.empty? || binary_list.size != 1

    lib_data.hash = binary_list.first
  rescue StandardError => _
    raise "fails in download binary: #{lib_data.url} with version: #{lib_data.version}"
  ensure
    (info_file&.close)
  end

  def self.download_binary_file(url, version, dst_file_path)
    puts "download binary: #{url} with version: #{version}" if PanConstants.debugging

    uri = URI(url)
    json_raw = Net::HTTP.get(uri)
    json_data = JSON.parse(json_raw)
    binary_uri = json_data[version]

    dst_file_path = './' + File.basename(URI(binary_uri).path) if dst_file_path.nil? || dst_file_path.empty?

    command = [
      wget_bin.to_s,
      "-O #{dst_file_path}",
      "#{binary_uri}",
      '--no-check-certificate',
      '-q',
      '--show-progress;'
    ].join(' ').strip.freeze

    system(command)
  end

  def self.unzip(zip_file, file_to_unzip, dir)
    raise "fatal: invalid zip file :#{zip_file}" unless File.exist?(zip_file.to_s)

    Zip::File.open(zip_file.to_s) do |each_file|
      # Handle entries one by one
      each_file.each do |entry|
        meta = %r{(.\/)?(([._\-\w\d*]+\/)*)(#{file_to_unzip})([._\-\w\d*\/]*)}.match(entry.name)

        if meta && meta[4] == file_to_unzip
          f_path = File.join(dir, "#{meta[4]}#{meta[5]}")
          FileUtils.mkdir_p(File.dirname(f_path))
          each_file.extract(entry, f_path) unless File.exist? f_path
        end
      end
    end
  end

  private_class_method def self.check_wget
    !`type wget 2> /dev/null;`.empty?
  end

  private_class_method def self.wget_bin
    `which wget`.to_s.strip.freeze
  end
end
