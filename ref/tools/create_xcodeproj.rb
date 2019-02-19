# encoding: UTF-8
# coding: UTF-8
# -*- coding: UTF-8 -*-

require 'xcodeproj'
require 'net/http'
require 'json'

raise "wrong args usage" unless ARGV.length >= 1
raise "unexcept scheme target" unless ["universal","blue","ipad"].include?(ARGV[0])

scheme_target = "bili-"+ARGV[0]

Dir.chdir scheme_target

cartfile_resolved = {}
cartfile = {}
user_env = ((ARGV.length >= 2 and ARGV[1] != "builder") or ARGV.length == 1)
need_gen_resolver = (ARGV.length >= 2 and ARGV[1] == "carthage")
need_sync = (ARGV.length >= 2 and ARGV[1] == "sync")

MAXIMUM_DUMMY_NUMBER_IN_TEMPLATE = 10

name_map = {

    # 1: 最上层逻辑 ################################################################

    "bililive-hd-ios" => [{
        :framework_name => "BBLivePad",
    }],
    "ios-link" => [{
        :framework_name => "BBLink",
    }],
    "ios-pictureshow" => [{
        :framework_name => "BBPictureShow",
    }],
    "ios-videoclip" => [{
        :framework_name => "BBVideoClip",
    }],
    "ios-videoclipshow" => [{
        :framework_name => "BBVideoClipShow",
    }],

    # 2: 拆分出去的业务方 ################################################################

    "ios-base" => [{
        :framework_name => "BPlusBase",
        :spec => 2,
    }],
    "ios-myfollowing" => [{
        :framework_name => "BBMyFollowing",
        :spec => 1,
        }, {
        :framework_name => "BPCFollowing",
        :xcodeproj_path => "BPCFollowing/BPCFollowing.xcodeproj",
        :spec => 2,
    }],
    "bililive-ios-base" => [{
        :framework_name => "BBLiveBase",
        :spec => 2,
    }],
    "BBPegasus" => [{
        :framework_name => "BBPegasus",
        :spec => 2,
    }],
    "BBPlayer" => [{
        :framework_name => "BBPlayer",
        :spec => 2,
    }],

    # 3: 中间件 ################################################################

    "BFCPlayer" => [{
        :framework_name => "BFCPlayer",
        :spec => 3,
    }],
    "BFCDanmaku" => [{
        :framework_name => "BFCDanmaku",
        :spec => 3,
    }],
    "BFCShare" => [{
        :framework_name => "BFCShare",
        :spec => 3,
    }],
    "BFCComment" => [{
        :framework_name => "BFCComment",
        :spec => 3,
    }],
    "BFCPaymentSDK" => [{
        :framework_name => "BFCPaymentSDK",
        :spec => 3,
    }],
    "BFCLauncher" => [{
        :framework_name => "BFCLauncher",
        :spec => 3,
    }],

    # 4: 底层库 ################################################################

    "ijkplayer" => [{
        :framework_name => "IJKMediaFrameworkWithSSL",
        :xcodeproj_path => "ios/IJKMediaPlayer/IJKMediaPlayer.xcodeproj",
        :spec => 4,
    }],
    "DanmakuFlameMaster-iOS" => [{
        :framework_name => "DanmakuFlameMaster",
        :xcodeproj_path => "DanmakuFlameMaster.xcodeproj",
        :spec => 4,
    }],
    "ios-android-gles-renderer" => [{
        :framework_name => "glrenderer",
        :xcodeproj_path => "ios/renderer.xcodeproj",
        :spec => 4,
    }],
    "lottie-ios" => [{
        :framework_name => "Lottie",
	    :xcodeproj_path => "Lottie.xcodeproj",
        :spec => 4,
    }],
    "BFCTXPlayer" => [{
        :framework_name => "BFCTXPlayerWrapper",
        :xcodeproj_path => "BFCTXPlayer.xcodeproj",
        :spec => 4,
    }, {
        :framework_name => "BFCTXMediaPlayerUniversal",
        :xcodeproj_path => "BFCTXPlayer.xcodeproj",
        :spec => 4,
    }, {
        :framework_name => "BFCTXMediaPlayerHD",
        :xcodeproj_path => "BFCTXPlayer.xcodeproj",
        :spec => 4,
    }],

    "BFC" => [{
        :framework_name => "BFCApiClient",
        :xcodeproj_path => "BFCApiClient/BFCApiClient.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCModManager",
        :xcodeproj_path => "BFCModManager/BFCModManager.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCRuler",
        :xcodeproj_path => "BFCRuler/BFCRuler.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCTracker",
        :xcodeproj_path => "BFCTracker/BFCTracker.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCUIKit",
        :xcodeproj_path => "BFCUIKit/BFCUIKit.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCDownload",
        :xcodeproj_path => "Components/BFCDownload/BFCDownload.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCEmptyDataSet",
        :xcodeproj_path => "Components/BFCEmptyDataSet/BFCEmptyDataSet.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCEmptyDataSetPad",
        :xcodeproj_path => "Components/BFCEmptyDataSet/BFCEmptyDataSet.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCEmptyDataSetPhone",
        :xcodeproj_path => "Components/BFCEmptyDataSet/BFCEmptyDataSet.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCMediaResolver",
        :xcodeproj_path => "Components/BFCMediaResolver/BFCMediaResolver.xcodeproj",
        :spec => 4,
        }, {
        :framework_name => "BFCReport",
        :xcodeproj_path => "Components/BFCReport/BFCReport.xcodeproj",
        :spec => 4,
    }],
}

exclude_frameworks_map = {
    "bili-universal" => ["BFCTXMediaPlayerHD"],
    "bili-blue" => ["BBLivePad", "BBPad", "BBPgcPad", "BFCEmptyDataSetPad", "BFCTXMediaPlayerHD"],
    "bili-ipad" => ["BFCEmptyDataSetPhone", "BFCEmptyDataSetPhone", "BFCTXMediaPlayerUniversal", "BBUper", "BBMall", "BBMusic", "BBLink", "BBMyFollowing", "BPlusBase,", "BBColumn", "BBPgcPhone", "BBLive", "BBLiveBC", "BBPictureShow", "BBVideoClip", "BBVideoClipShow", "BBPhone"],
}

exclude_frameworks = exclude_frameworks_map[scheme_target]

IO.foreach("../Cartfile") {
    |block|
    block = block.strip
    if block == "" or block[0] == "\#"
        next
    end

    meta = /(binary|git)\s+"([^"]+)"\s+(((~>|==|>=)\s?(\d+(\.\d+)+))|("([^"]+)"))/.match(block)
    if meta and meta[1] == "git"
        f_name = /\/([^.\/]+)(.git)?$/.match(meta[2])[1]
        cartfile[f_name] = {
            :type => meta[1],
            :url => meta[2],
            :branch => meta[6]?meta[6]:meta[9],
        }
    else meta and meta[1] == "binary"
        f_name = /\/([^.\/]+)(.git)?$/.match(meta[2])[1]
        cartfile[f_name] = {
            :type => meta[1],
            :url => meta[2],
            :version => meta[6],
            :operator => meta[5],
        }
    end
}

cartfile.select {|name, value| value[:type]=="git"}
.each do |name, value|
    if !File.exist?("../Carthage/Repo/#{name}.git")
        if user_env
            system("git clone --bare -b #{value[:branch]} #{value[:url]} ../Carthage/Repo/#{name}.git")
        else
            system("git clone --bare -b #{value[:branch]} --depth 1 #{value[:url]} ../Carthage/Repo/#{name}.git")
        end
        system("cd ../Carthage/Repo/#{name}.git; git remote remove origin ;git remote add origin #{value[:url]};")
    end
    puts "Start Fetching #{name}"
    system("cd ../Carthage/Repo/#{name}.git; git fetch --all;")
    hs = `cd ../Carthage/Repo/#{name}.git; git rev-parse refs/remotes/origin/#{value[:branch]} 2> /dev/null;`.strip
    if hs.length != 40
        hs = `cd ../Carthage/Repo/#{name}.git; git rev-parse refs/tags/#{value[:branch]} 2> /dev/null;`.strip
        if hs.length != 40
            if `cd ../Carthage/Repo/#{name}.git; git cat-file -t #{value[:branch]}`.strip == "commit"
                system("cd ../Carthage/Repo/#{name}.git; git update-ref HEAD #{value[:branch][0..38]}")
                hs = value[:branch]
            end
        else
            system("cd ../Carthage/Repo/#{name}.git; git symbolic-ref HEAD refs/tags/#{value[:branch]};")
        end
    else
        system("cd ../Carthage/Repo/#{name}.git; "\
              + "git branch #{value[:branch]} 2> /dev/null; "\
              + "git update-ref refs/heads/#{value[:branch]} #{hs}; "\
              + "git symbolic-ref HEAD refs/heads/#{value[:branch]};"\
              + "git branch --set-upstream-to=origin/#{value[:branch]} #{value[:branch]}")
    end

    raise "unknow branch or tag or commit #{value}" unless hs.length == 40
    value[:hash] = hs.strip
end

if need_gen_resolver
    system("cd ..; carthage update --no-build --no-checkout --verbose;")
else
    File.open("../Cartfile.resolved", "w+") do |fd|
        cartfile.each do |name, value|
            if value[:type] == "binary"
                uri = URI(value[:url])
                uri.scheme = "http"
                uri = URI(uri.to_s)
                raw = Net::HTTP.get(uri)
                data = JSON.parse(raw)
                finded = false
                data.sort_by {|k,v| Gem::Version.new(k)}.reverse.each do |ver|
                    case value[:operator]
                    when "~>"
                        ovn = 0
                        tvn = 0
                        Gem::Version.new(ver[0]).segments.each_with_index do |n, idx|
                            ovn += (1000 ** (3-idx) * n)
                            raise "unsupport version format" unless (idx < 4 and n < 100)
                        end
                        Gem::Version.new(value[:version]).segments.each_with_index do |n, idx|
                            tvn += (1000 ** (3-idx) *n)
                            raise "unsupport version format" unless (idx < 4 and n < 100)
                        end
                        if ovn < tvn
                            break
                        end
                        if ovn - tvn < (1000 ** 3/10) and tvn >= 1000 ** 3
                            finded = true
                        end
                        if ovn - tvn < (1000 ** 2/10) and tvn < 1000 ** 3
                            finded = true
                        end
                    when "=="
                        if ver[0] == value[:version]
                            finded = true
                        end
                    when ">="
                        finded = true
                    else
                        raise "unknow operator #{value}"
                    end
                    if finded
                        fd.puts "binary \"#{value[:url]}\" \"#{ver[0]}\""
                        break
                    end
                end
                raise "unstatisfied version for #{value}" unless finded 
            elsif value[:type] == "git"
                fd.puts "git \"#{value[:url]}\" \"#{value[:hash]}\""
            else
                raise "unknown type of cartfile #{value}"
            end
        end
    end
end

IO.foreach("../Cartfile.resolved") {
    |block|
    if block == "" or block == "\n"
        next
    end
    
    meta = /(binary|git)\s+"([^"]+)"\s+"([^"]+)"/.match(block)
    type = meta[1]
    f_name = /\/([^.\/]+)(.git)?$/.match(meta[2])[1]
    url = meta[2]
    hash = meta[3]

    if exclude_frameworks and exclude_frameworks.include?(f_name)
        next
    end

    cartfile_resolved[f_name] = {
        :type => type,
        :hash => hash,
        :url => url,
    }
}

cartfile_resolved = cartfile_resolved.sort_by {|k, v| v[:type]}.reverse

project_path = scheme_target+'.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find {|nt| nt.name == scheme_target }
msgtarget = project.targets.find {|nt| nt.name == 'BiliIMessageExtension'}
widgettarget = project.targets.find {|nt| nt.name == 'BiliWidgetExtension'}
notificationtarget = project.targets.find {|nt| nt.name == 'BiliNotificationServiceExtension'}

dummy_targets = Array.new

for i in 1..MAXIMUM_DUMMY_NUMBER_IN_TEMPLATE
    dummy_target_name = "Dummy#{i}"
    dummy_target = project.targets.find {|nt| nt.name == dummy_target_name}
    dummy_target.dependencies.clear
    dummy_targets.insert(i, dummy_target)
    target.add_dependency(dummy_target)
end

for i in 1..(MAXIMUM_DUMMY_NUMBER_IN_TEMPLATE - 1)
    for j in (i + 1)..MAXIMUM_DUMMY_NUMBER_IN_TEMPLATE
        dummy_targets[i].add_dependency(dummy_targets[j])
    end
end

link = target.frameworks_build_phases
embed = target.copy_files_build_phases[1]
strip = target.shell_script_build_phases[1]
shell = target.shell_script_build_phases[2]

framework_group = project['Frameworks']
project_group = project['Projects']

# framework_group.clear
# project_group.clear
# link.clear
embed.clear
strip.input_paths.clear
strip.output_paths.clear
shell.input_paths.clear
shell.output_paths.clear
target.dependencies.clear

if not msgtarget.nil?
    target.add_dependency(msgtarget)
end
if not widgettarget.nil?
    target.add_dependency(widgettarget)
    widgettarget.add_dependency(dummy_targets[4])
end
if not notificationtarget.nil?
    target.add_dependency(notificationtarget)
    notificationtarget.add_dependency(dummy_targets[4])
end

cartfile_resolved.select {|key, value| true}
.each do |key, value|
    name = key
    case value[:type]
    when "binary"
        framework_name = name_map.has_key?(name) ? name_map[name].first[:framework_name] : name
        system("cd ../ && carthage bootstrap --platform iOS --verbose #{name} && cd #{scheme_target}")
        file_ref = framework_group.new_reference("../Carthage/Build/iOS/#{name}.framework")
        file_ref_name = file_ref.name

        if link.files.none? {|pf| pf.display_name == file_ref_name}
            link.add_file_reference(file_ref)
        end
        if embed.files.none? {|pf| pf.display_name == file_ref_name}
            embed.add_file_reference(file_ref)
            embed.build_file(file_ref).settings = {"ATTRIBUTES" => ['CodeSignOnCopy', 'RemoveHeadersOnCopy']}
            strip.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/#{framework_name}.framework")

            ipth = "../Carthage/Build/iOS/#{framework_name}.framework/#{framework_name}"
            if File.exist?(ipth)
                fr = `file #{ipth}`
                puts fr
                if fr.include?("dynamically linked shared library")
                    shell.input_paths.push("$(SRCROOT)/../Carthage/Build/iOS/#{framework_name}.framework")
                    shell.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/#{framework_name}.framework")
                end
            end
        end

    when "git"
        # 1. 在 Checkouts 目录下，建立对应的 git 工作区，并与 Repo 目录中的 git 裸仓关联
        command = ""
        if user_env
            command += "git init --separate-git-dir=../../Repo/#{name}.git;"
            if need_sync
                command += "git reset --hard -q; git pull;"
            else
                command += "git reset -q;"
            end
        end

        system("cd ../; carthage bootstrap --platform iOS --verbose --no-build #{name};"\
            + "mkdir -p Carthage/Checkouts/#{name}/Carthage/ ; cd $_ ;"\
            + "ln -s ../../../Build . ; cd ../;"\
            + command)
        if need_sync
            next
        end
        # 2. 遍历一个 git 仓下的所有 xcodeproject，并依次添加到壳工程中

        project_meta_array = name_map.has_key?(name) ? name_map[name] : [ { :framework_name => name } ]
        project_meta_array.each do |project_meta|

            framework_name = project_meta[:framework_name]
            xcodeproj_path = project_meta.has_key?(:xcodeproj_path) ? project_meta[:xcodeproj_path] : "#{framework_name}.xcodeproj"

            if exclude_frameworks and exclude_frameworks.include?(framework_name)
                next
            end

            spec_num = project_meta.has_key?(:spec) ? project_meta[:spec] : 1
            raise "error: #{name}[:spec] > #{MAXIMUM_DUMMY_NUMBER_IN_TEMPLATE}" unless spec_num > 0 and spec_num <= MAXIMUM_DUMMY_NUMBER_IN_TEMPLATE
            add_to_target = dummy_targets[spec_num]

            # 2.1 将子工程加入到壳工程的目录树中
            project_group.new_reference("../Carthage/Checkouts/#{name}/#{xcodeproj_path}")
            map = project.objects_by_uuid

            # 2.2 壳工程 link & embed 子工程的产物 framework
            project.root_object.project_references.each do |project_reference|
                product_group_uuid = project_reference[:product_group].uuid

                product_group_objects = (map[product_group_uuid]).children
                matched_product_object = (product_group_objects.select do |product_object| 
                    product_object.path == framework_name + ".framework"
                end).first
                if matched_product_object
                    matched_product_ref = map[matched_product_object.uuid]
                    matched_product_name = matched_product_ref.path

                    if link.files.none? { |file_name| file_name.display_name == matched_product_name }
                        link.add_file_reference(matched_product_ref)
                    end

                    if embed.files.none? { |file_name| file_name.display_name == matched_product_name}
                        embed.add_file_reference(matched_product_ref)
                        embed.build_file(matched_product_ref).settings = { "ATTRIBUTES" => ['CodeSignOnCopy', 'RemoveHeadersOnCopy' ]}
                        strip.output_paths.push("$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/#{framework_name}.framework")
                    end
                end
            end

            # 2.3 将子工程加入到壳工程的 target dependencies 中
            sub_project = Xcodeproj::Project.open("../Carthage/Checkouts/#{name}/#{xcodeproj_path}")
            matched_target = (sub_project.targets.select { |target_object| target_object.name == framework_name }).first
            if matched_target
                add_to_target.add_dependency(matched_target)

                # 2.4 在编译机环境下为子依赖加入dummy的依赖
                if !user_env and sub_project['Dependencies']
                    sub_project_group = sub_project['Dependencies']
                    sub_project_group.new_reference("#{File.dirname(__dir__)}/#{scheme_target}/#{scheme_target}.xcodeproj")
                    for i in (spec_num + 1)..MAXIMUM_DUMMY_NUMBER_IN_TEMPLATE
                        matched_target.add_dependency(dummy_targets[i])
                    end
                    sub_project.save
                end
            end

        end

    else
        raise "unknow file type"
    end
    puts key
end

puts "-------------------"
if !need_sync
    #project.sort
    project.save
    puts "generate success"
else
    puts "sync success"
end

