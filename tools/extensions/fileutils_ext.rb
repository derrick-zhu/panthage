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

    all_files = traverse_dir(dir, true)
    all_files.sort_by(&:length)

    count = all_files.size
    idx = 0

    all_files.each do |filepath|
      if PanConstants.debugging
        print "\rSearching #{file_path_to_find} #{idx}/#{count}..."
        idx += 1
      end

      next if result.select {|already_found| filepath.start_with?(already_found)}.size.positive?

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

  private_class_method def self.traverse_dir(file_path, is_skip_symlink = false)
                         file_path = file_path[0..file_path.length - 2] if file_path.end_with? '/'

                         result = []
                         return result if (File.symlink? file_path) && is_skip_symlink

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
