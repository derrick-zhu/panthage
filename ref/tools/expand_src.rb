cartfile = {}
name_map = {
    "BPlusBase" => {
        :repo_name => "ios-base",
        :group => "bplus",
    },
    "BBLink" => {
        :repo_name => "ios-link",
        :group => "bplus",
    },
    "BBMyFollowing" => {
        :repo_name => "ios-myfollowing",
        :group => "bplus",
    },
    "BBLivePad" => {
        :repo_name => "bililive-hd-ios",
        :group => "live",
    },
    "BBLiveBase" => {
        :repo_name => "bililive-ios-base",
        :group => "live",
    },
    "BBPictureShow" => {
        :repo_name => "ios-pictureshow",
        :group => "bplus",
    },
    "BBVideoClip" => {
        :repo_name => "ios-videoclip",
        :group => "bplus",
    },
    "BBLive" => {
        :repo_name => "BBLive",
        :group => "ios",
    },
    "BBLiveBC" => {
        :repo_name => "BBLiveBC",
        :group => "live",
    },
    "BBVideoClipShow" => {
        :repo_name => "ios-videoclipshow",
        :group => "bplus",
    },
    "IJKMediaFrameworkWithSSL" => {
        :repo_name => "ijkplayer",
        :group => "app",
    },
    "DanmakuFlameMaster" => {
        :repo_name => "DanmakuFlameMaster-iOS",
        :group => "app",
    },
    "BFCTXPlayerWrapper" => {
        :repo_name => "BFCTXPlayer",
        :group => "ios",
    },
}

skipped = ["BFCApiClient", "BFCDownload", "BFCEmptyDataSet", "BFCEmptyDataSetPad", "BFCEmptyDataSetPhone", "BFCMediaResolver", "BFCModManager",
"BFCPaymentSDK", "BFCReport", "BFCTracker", "BFCUIKit", "BFCRuler", "BPCFollowing", "glrenderer", "LFLiveKit", "Lottie", "BFCComment", "BFCTXMediaPlayerHD", "BFCTXMediaPlayerUniversal","GPUImage","ExpressPlay","BGRenderer","NvStreamingSdkCore"]

IO.foreach("Cartfile") {
    |block|
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

File.open("Cartfile", "w+") do |fd|
    cartfile.select {|key, value| true }.each do |name, value|
        puts name
        if value[:type] == "binary"
            if skipped.include?(name)
                fd.puts "binary \"#{value[:url]}\" #{value[:operator]} #{value[:version]}"
            else
                repo = name
                group = "ios"
                if name_map.has_key?(repo)
                    group = name_map[repo][:group]
                    repo = name_map[repo][:repo_name]
                end
                prefix = (repo == "ijkplayer") ? "k" : ""
                fd.puts "git \"git@git.bilibili.co:#{group}/#{repo}.git\" \"#{prefix}#{value[:version]}\""
            end
        elsif value[:type] == "git"
            fd.puts "git \"#{value[:url]}\" \"#{value[:branch]}\""
        else
            raise "unknown type of cartfile #{value}"
        end
    end
end
