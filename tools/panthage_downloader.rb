#!/usr/bin/ruby
# frozen_string_literal: true

require 'rubygems'
require 'zip'
require 'down'
require 'json'

require_relative 'panthage_ver_helper'
require_relative 'extensions/string_ext'
require_relative 'utils/panthage_progress_bar'

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

  def self.fetch_remote_content_length(url)
    remote_io = Down.open(url)
    result = remote_io.size
    remote_io.close

    result
  end

  def self.download_binary_file(url, version, dst_file_path)
    remote_json_raw = Down.open(url)
    remote_json = JSON.parse(remote_json_raw.read)
    binary_uri = remote_json[version]
    remote_json_raw.close

    dst_file_path = './' + File.basename(URI(binary_uri).path) if dst_file_path.nil? || dst_file_path.empty?

    # 如果已经存在本地文件，比较和远程文件的大小之后，在判断是否需要下载
    if File.exists? dst_file_path
      local_file_size = File.size? dst_file_path
      remote_file_size = fetch_remote_content_length(binary_uri)
      return unless local_file_size != remote_file_size
    end

    puts "download binary: #{url} with version: #{version}" if PanConstants.debugging

    remote_file_size = 0
    idx = 0
    piece_download = 0
    Down.download binary_uri,
                  content_length_proc: -> (content_length) {remote_file_size = content_length},
                  progress_proc: -> (progress) do
                    if remote_file_size != progress
                      print "\r#{Bar.moon[idx]}\t#{progress * 100 / remote_file_size}% downloading..." unless remote_file_size == 0

                      piece_download += progress
                      if piece_download > 1024
                        idx = (idx + 1) % Bar.moon.size
                        piece_download = 0
                      end

                    else
                      print "\rDone."
                      print "\n"
                    end

                  end,
                  destination: dst_file_path
  end

  def self.unzip(zip_file, file_to_unzip, dir)
    raise "fatal: invalid zip file :#{zip_file}" unless File.exist?(zip_file.to_s)

    reg_unzip = file_to_unzip.gsub(/[.]/, '\.')
    reg_unzip = reg_unzip.gsub(/[*]/, '(.*)')
    reg_unzip = reg_unzip.gsub(/[?]/, '.')

    found = false

    Zip::File.open(zip_file.to_s) do |each_file|
      # Handle entries one by one
      each_file.each do |entry|
        meta = %r{(.\/)?(([._\-\w\d*]+\/)*)(#{reg_unzip})([._\-\w\d*\/]*)}.match(entry.name)

        if meta && !meta[4].empty?
          found = true
          f_path = File.join(dir, "#{meta[4]}#{meta[6]}")
          FileUtils.mkdir_p(File.dirname(f_path))
          each_file.extract(entry, f_path) unless File.exist? f_path
        end
      end
    end

    found
  end

  private_class_method def self.check_wget
                         !`type wget 2> /dev/null;`.empty?
                       end

  private_class_method def self.wget_bin
                         `which wget`.to_s.strip.freeze
                       end
end
