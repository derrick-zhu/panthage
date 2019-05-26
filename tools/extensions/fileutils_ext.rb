#!/usr/bin/ruby
#

require 'find'
require 'fileutils'

module FileUtils
  def self.find_path_in_r(file_path_to_find, dir = '.', exclude_dir = '')
    [''] unless File.exist? dir

    result = []

    final_filepath = file_path_to_find.gsub(/[.]/, '\.')
    final_filepath = final_filepath.gsub(/[*]/, '(.*)')
    final_filepath = final_filepath.gsub(/[?]/, '.')

    all_files = traverse_dir(dir)

    all_files.each do |filepath|
      if !exclude_dir.nil? && !exclude_dir.empty?
        final_exclude_dir = exclude_dir.gsub(/[.]/, '\.')
        final_exclude_dir = final_exclude_dir.gsub(/[*]/, '(.*)')
        final_exclude_dir = final_exclude_dir.gsub(/[?]/, '.')

        exclude_meta = %r{([._\-\w\d*]+\/)*(#{final_exclude_dir}\/?)}.match(filepath.to_s)
        next unless exclude_meta.nil?
      end

      meta = %r{([\/._\-\w\d*]+\/)*(#{final_filepath}(\/)?$)}.match(filepath.to_s)
      if !meta.nil? && !meta[0].empty?
        result.append meta[0]
      end
    end

    result
  end

  private_class_method def self.traverse_dir(file_path)
                         result = []

                         if file_path.end_with? '/'
                           file_path = file_path[0..file_path.length - 2]
                         end

                         if File.directory? file_path
                           result.append(file_path)
                           Dir.foreach(file_path) do |file|
                             result.concat(traverse_dir(file_path + "/" + file)) if file != "." and file != ".."
                           end
                         else
                           result.append(file_path)
                         end

                         result
                       end
end
