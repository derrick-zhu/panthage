#!/usr/bin/ruby
# frozen_string_literal: true

require_relative 'panthage_dependency'
require_relative 'panthage_cartfile'
require_relative 'panthage_ver_helpr'

# GitRepo git repo helper class
class GitRepo
  def self.type(value)
    if value.branch
      GitRepoType::BRANCH
    elsif value.tag
      GitRepoType::TAG
    else
      GitRepoType::UNKNOWN
    end
  end
end

# setup_carthage_env check and setup the environments
def setup_carthage_env(current_dir)
  env_paths = Array[
      "#{current_dir}/Carthage",
      "#{current_dir}/Carthage/.tmp",
      "#{current_dir}/Carthage/Checkouts",
      "#{current_dir}/Carthage/Build",
      "#{current_dir}/Carthage/Repo"
  ]

  # mkdir if folder is NOT existed.
  env_paths.each do |each_path|
    FileUtils.mkdir_p each_path.to_s unless File.exist? each_path.to_s
  end
end

def merge_cart_file(old_cart, new_cart)
  need_added_data = {}

  new_cart.each do |new_name, new_data|
  
    if old_cart.has_key?(new_name)
      old_data = old_cart[new_name]

      case old_data.type
      when 'git'
        if new_data.tag != nil and old_data.tag != nil
          new_major = VersionHelper.majorNo(new_data.tag)
          new_minor = VersionHelper.minorNo(new_data.tag)
          old_major = VersionHelper.majorNo(old_data.tag)
          old_minor = VersionHelper.minorNo(old_data.tag)

          if new_major != old_major
            old_data.conflict = ConflictType.ERROR
            old_data.error_msg = show_conflict_git(new_data, old_data)
            raise "halt !!! #{old_data.error_msg}"

          elsif new_minor != old_minor
            new_data.conflict = ConflictType.WARNING
            new_data.error_msg = "warning: #{new_name} version update #{old_data.tag} -> #{new_data.tag}"
            need_added_data[new_name] = new_data

          else
            new_data.conflict = ConflictType.OK
            need_added_data[new_name] = new_data
          end

        elsif new_data.branch != nil and old_data.branch != nil
          unless new_data.url == old_data.url and new_data.branch == old_data.branch
            old_data.conflict = ConflictType.ERROR
            old_data.error_msg = show_conflict_branch(new_data, old_data)
            raise "halt !!! #{old_data.error_msg}"
          end

        elsif new_data.branch != nil and old_data.tag != nil
          new_data.conflict = ConflictType.WARNING
          new_data.error_msg = "warning: #{new_name} framework update: #{old_data.tag} -> #{new_data.url}:#{new_data.branch}"
          need_added_data[new_name] = new_data
          
        end

      when 'binary'
        new_url = new_data.url
        new_version = new_data.version

        old_url = old_data.url
        old_version = old_data.version

        unless new_url == old_url
          old_data.conflict = ConflictType.ERROR
          old_data.error_msg = "conflict framework library #{old_name} had the conflict url: \n #{old_data.url} \nand\n #{new_dat.url} "
          raise "halt !!! #{old_data.error_msg}"
        end 
        
        new_major = VersionHelper.majorNo(new_version)
        new_minor = VersionHelper.minorNo(new_version)

        old_major = VersionHelper.majorNo(old_version)
        old_minor = VersionHelper.minorNo(old_version)

        if new_major != old_major
          old_data.conflict = ConflictType.ERROR
          old_data.error_msg = "conflict framework version:\n#{new_data.version} by #{new_data.proj_name}\n#{old_data.version} by #{old_data.proj_name}"
          raise "halt !!! #{old_data.error_msg}"
        elsif new_minor ! old_minor
          new_data.conflict = ConflictType.WARNING
          new_data.error_msg = "warning: #{new_name} version update #{old_data.version} -> #{new_data.version}"
          need_added_data[new_name] = new_data
        end

      end

    else  # not has key 'new_name'
      new_data.conflict = false
      need_added_data[new_name] = new_data

    end
  #   old_cart.select { |old_name, _| old_name == new_name }
  #           .each do |each_name, each_data|
  #     if each_data.type == 'git'
  #       if each_data.tag

  #         # new_ver = VersionHelper.to_i(new_data.tag)
  #         new_major = VersionHelper.majorNo(new_data.tag)
  #         new_minor = VersionHelper.minorNo(new_data.tag)
  #         # old_ver = VersionHelper.to_i(each_data.tag)
  #         old_major = VersionHelper.majorNo(each_data.tag)
  #         old_minor = VersionHelper.minorNo(each_data.tag)

  #         if new_major != old_major
  #           new_data.conflict = true
  #           show_conflict_tag(new_data, old_data)
  #           raise 'halt!!!'

  #         elsif new_minor > old_minor
  #           new_data.conflict = false
  #           need_added_data[new_name] = new_data

  #         end

  #       elsif each_data.branch
  #         # TODO: compare the hash and the repo's url

  #       end
  #     elsif each_data.type == 'binary'
  #     else
  #       puts "unknown type #{each_data.type} of #{each_name}"
  #     end
  #   end
  # end
end

def show_conflict_tag(new_data, old_data)
  "conflict framework version:\n#{new_data.tag} by #{new_data.proj_name}\n#{old_data.tag} by #{old_data.proj_name}"
end

def show_conflict_branch(new_data, old_data)
  "conflict framework version:\n#{new_data.branch} by #{new_data.proj_name}\n#{old_data.branch} by #{old_data.proj_name}"
end

# read_cart_file Reading data from cartfile
def read_cart_file(proj_name, cart_file)
  cartFileData = {}

  if File.exist? cart_file
    IO.foreach(cart_file) do |block|
      block = block.strip
      next if (block == '') || (block[0] == "\#")

      meta = /(binary|git|github)\s+"([^"]+)"\s+(((~>|==|>=)\s?(\d+(\.\d+)+))|("([^"]+)"))/.match(block)

      puts meta.to_s if PanConstants.debuging

      if meta && (meta[1] == 'git')
        f_name = %r{/([^./]+)(.git)?$}.match(meta[2])[1]
        cartFileData[f_name] = Cartfile.new_git(proj_name, meta[1], meta[2], meta[6], meta[9])

      elsif meta && (meta[1] == 'binary')
        f_name = %r{/([^./]+)(.json)?$}.match(meta[2])[1]
        cartFileData[f_name] = Cartfile.new_binary(proj_name, meta[1], meta[2], meta[6], meta[5])

      elsif meta && (meta[1] == 'github')
        puts meta[1]

      end
    end
  end

  cartFileData
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

    cartfile_resolved[f_name] = CartfileResolved.new_cart_solved(f_name, type, url, hash)
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
      if value.type == 'binary'
        uri = URI(value.url)
        # uri.scheme = 'http'
        uri = URI(uri.to_s)
        raw = Net::HTTP.get(uri)
        data = JSON.parse(raw)
        finded = false
        data.sort_by { |k, _v| Gem::Version.new(k) }
            .reverse_each do |ver|
          case value.operator
          when '~>'
            ovn = to_i(ver[0])
            tvn = to_i(value.version)

            break if ovn < tvn

            finded = true if (ovn - tvn < (1000**3 / 10)) && (tvn >= 1000**3)
            finded = true if (ovn - tvn < (1000**2 / 10)) && (tvn < 1000**3)

          when '=='
            finded = true if ver[0] == value.version

          when '>='
            finded = true

          else
            raise "unknow operator #{value}"

          end

          if finded
            array_cartfile_resolve.push("binary \"#{value.url}\" \"#{ver[0]}\"")
            break
          end
        end

        raise "unstatisfied version for #{value}" unless finded

      elsif value.type == 'git'
        array_cartfile_resolve.push("git \"#{value.url}\" \"#{value.hash}\"")

      else
        raise "unknown type of cartfile #{value}"

      end
    end

    carfile_resolve_content = array_cartfile_resolve.sort_by { |a, _b| a }
                                                    .join("\n")

    File.open("#{current_dir}/Cartfile.resolved", 'w+') do |fd|
      fd.puts carfile_resolve_content
    end
  end
end

# clone_bare_repo - clone the bare repo
def clone_bare_repo(repo_dir_base, name, value, using_install)
  puts "#{'***'.cyan} Start fetching #{name.green.bold}"

  repo_dir = "#{repo_dir_base}/#{name}.git"
  git_target_head = ''

  # using tag or branch ?
  if GitRepo.type(value) == GitRepoType::TAG
    git_target_head = value.tag
  elsif GitRepo.type(value) == GitRepoType::BRANCH
    git_target_head = value.branch
  else
    raise 'no target branch or tag?'
  end

  # clone
  unless File.exist? repo_dir
    command = "git clone --bare -b #{git_target_head} "
    command += '--depth 1 ' if using_install
    command += "#{value.url} #{repo_dir} #{$g_verbose}; "

    puts "#{'***'.cyan} Cloning #{name.green.bold}"

    system(command)
    system("cd #{repo_dir}; git remote remove origin; git remote add origin #{value.url};")

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
  value.hash = commit_hash.strip

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
