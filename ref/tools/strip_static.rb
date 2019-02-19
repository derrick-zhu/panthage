#!/usr/bin/ruby

raise "wrong args usage" unless ARGV.length == 3

meta = /\/Frameworks\/(\S+)\.framework/.match(ARGV[0])
str = ARGV[0]
signid = ARGV[1]
dymmy = ARGV[2]
puts str

if File.exist?(str+"/#{meta[1]}")
    fr = `file #{str}/#{meta[1]}`
    if not fr.include?("dynamically linked shared library")
        File.delete(str+"/#{meta[1]}")
        system("cp #{dymmy} #{str}/#{meta[1]}")
        puts "file delete #{str}#{meta[1]}"
		system("/usr/bin/codesign --force --sign #{signid} --preserve-metadata=identifier,entitlements,flags --timestamp=none #{str}")
    end
end
