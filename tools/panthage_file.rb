#!/usr/bin/ruby
# frozen_string_literal: true

require_relative 'panthage_dependency'

# read_cart_file Reading data from cartfile
def read_cart_file(cart_file)
  cartfile = {}

  if File.exist? cart_file
    IO.foreach(cart_file) do |block|
      block = block.strip
      next if (block == '') || (block[0] == "\#")

      meta = /(binary|git|github)\s+"([^"]+)"\s+(((~>|==|>=)\s?(\d+(\.\d+)+))|("([^"]+)"))/.match(block)

      puts meta.to_s if PanConstants.debuging

      if meta && (meta[1] == 'git')
        f_name = %r{/([^./]+)(.git)?$}.match(meta[2])[1]
        cartfile[f_name] = {
          type: meta[1],
          url: meta[2],
          tag: meta[6],
          branch: meta[9]
        }
      elsif meta && (meta[1] == 'binary')
        f_name = %r{/([^./]+)(.json)?$}.match(meta[2])[1]
        cartfile[f_name] = {
          type: meta[1],
          url: meta[2],
          version: meta[6],
          operator: meta[5]
        }
      elsif meta && (meta[1] == 'github')
        puts meta[1]
      end
    end
  end

  cartfile
end

# read_cart_solved_file - read the data of the solved cartfile
def read_cart_solved_file(current_dir)
  cartfile_resolved = {}

  IO.foreach("#{current_dir}/Cartfile.resolved") do |block|
    next if (block == '') || (block == "\n")

    meta = /(binary|git|github)\s+"([^"]+)"\s+"([^"]+)"/.match(block)

    if meta
      type = meta[1]
      f_name = %r{/([^./]+)(.git|.json)?$}.match(meta[2])[1]
      url = meta[2]
      hash = meta[3]
    else
      puts "#{'***'.cyan} warning could not analysis #{block}"
      next
    end

    cartfile_resolved[f_name] = {
      type: type,
      hash: hash,
      url: url
    }
  end

  cartfile_resolved
end

# solve_cart_file solve and analysis the cartfile
def solve_cart_file(current_dir, cartfile, using_carthage)
  if using_carthage
    system "cd #{current_dir}; carthage update --no-build --no-checkout --verbose --new-resolver;"
  else
    array_cartfile_resolve = []
    cartfile.each do |_name, value|
      if value[:type] == 'binary'
        uri = URI(value[:url])
        # uri.scheme = 'http'
        uri = URI(uri.to_s)
        raw = Net::HTTP.get(uri)
        data = JSON.parse(raw)
        finded = false
        data.sort_by { |k, _v| Gem::Version.new(k) }.reverse_each do |ver|
          case value[:operator]
          when '~>'
            ovn = 0
            tvn = 0
            Gem::Version.new(ver[0]).segments.each_with_index do |n, idx|
              ovn += (1000**(3 - idx) * n)
              raise 'unsupport version format' unless (idx < 4) && (n < 100)
            end
            Gem::Version.new(value[:version]).segments.each_with_index do |n, idx|
              tvn += (1000**(3 - idx) * n)
              raise 'unsupport version format' unless (idx < 4) && (n < 100)
            end
            break if ovn < tvn

            finded = true if (ovn - tvn < (1000**3 / 10)) && (tvn >= 1000**3)
            finded = true if (ovn - tvn < (1000**2 / 10)) && (tvn < 1000**3)
          when '=='
            finded = true if ver[0] == value[:version]
          when '>='
            finded = true
          else
            raise "unknow operator #{value}"
          end
          if finded
            array_cartfile_resolve.push("binary \"#{value[:url]}\" \"#{ver[0]}\"")
            break
          end
        end
        raise "unstatisfied version for #{value}" unless finded
      elsif value[:type] == 'git'
        array_cartfile_resolve.push("git \"#{value[:url]}\" \"#{value[:hash]}\"")
      else
        raise "unknown type of cartfile #{value}"
      end
    end

    carfile_resolve_content = array_cartfile_resolve.sort_by { |a, _b| a }.join("\n")

    File.open("#{current_dir}/Cartfile.resolved", 'w+') do |fd|
      fd.puts carfile_resolve_content
    end # open Cartfile.
  end
end

# clone_bare_repo - clone the bare repo
def clone_bare_repo(repo_dir_base, name, value)
  puts "#{'***'.cyan} Start fetching #{name.green.bold}"

  repo_dir = "#{repo_dir_base}/#{name}.git"
  git_target_head = ''

  # using tag or branch ?
  if GitRepo.type(value) == GitRepoType::TAG
    git_target_head = value[:tag]
  elsif GitRepo.type(value) == GitRepoType::BRANCH
    git_target_head = value[:branch]
  else
    raise 'no target branch or tag?'
  end

  # clone
  unless File.exist? repo_dir
    command = "git clone --bare -b #{git_target_head} "
    command += '--depth 1 ' if command_install?(job_command)
    command += "#{value[:url]} #{repo_dir} #{$g_verbose}; "

    puts "#{'***'.cyan} Cloning #{name.green.bold}"

    system(command)
    system("cd #{repo_dir}; git remote remove origin; git remote add origin #{value[:url]};")

    puts "#{'***'.cyan} Finished!"
  end

  # fetch the commit hash value by using branch name or tags
  system("cd #{repo_dir}; git fetch --all  #{$g_verbose}")

  if GitRepo.type(value) == GitRepoType::TAG
    commit_hash = `cd #{repo_dir}; git rev-parse refs/tags/#{git_target_head} 2> /dev/null;`.strip.freeze

    if commit_hash.length == 40
      system("cd #{repo_dir}; git symbolic-ref HEAD refs/tags/#{git_target_head};")

    elsif `cd #{repo_dir}; git cat-file -t #{git_target_head}`.strip == 'commit'
      system("cd #{repo_dir}; git update-ref HEAD #{git_target_head};")
      commit_hash = git_target_head.to_s

    end

  elsif GitRepo.type(value) == GitRepoType::BRANCH
    print "#{'***'.cyan} "

    commit_hash = `cd #{repo_dir}; git rev-parse refs/remotes/origin/#{git_target_head} 2> /dev/null;`.strip.freeze

    if commit_hash.length == 40
      system("cd #{repo_dir};" \
        + "git branch #{git_target_head} 2> /dev/null;" \
        + "git update-ref refs/heads/#{git_target_head} #{commit_hash};" \
        + "git symbolic-ref HEAD refs/heads/#{git_target_head};" \
        + "git branch --set-upstream-to=origin/#{git_target_head} #{git_target_head}")
    end

  end

  raise "unknow branch or tag or commit #{value} and commit hash:#{commit_hash}." unless commit_hash.length == 40

  # save the commit's SHA1 hash.
  value[:hash] = commit_hash.strip

  print "#{'***'.cyan} Fetch #{name.green.bold} Done.\n\n"
end

def download_binary_file(url, version, dst_file_path)
  uri = URI(url)
  json_raw = Net::HTTP.get(uri)
  json_data = JSON.parse(json_raw)
  binary_uri = json_data[version]
  puts "binary url: #{binary_uri}"

  output_binary = File.open(dst_file_path, 'wb+')

  begin
    resp = nil
    max_limited = 10
    cur_limited = 0


    Net::HTTP.start(URI(binary_uri).host) do |http|
      puts http.head(URI(binary_uri).path).head
    end

    begin
      resp = Net::HTTP.get_response(URI.parse(binary_uri))
      binary_uri = resp['location']
      
      cur_limited += 1
      break if cur_limited >= max_limited
    end while resp.is_a?(Net::HTTPRedirection)

    output_binary.write(resp.body)

  ensure
    output_binary.close
  end
end
