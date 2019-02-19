#!/usr/bin/ruby

raise "wrong args usage" unless ARGV.length == 2

REG_PARAM = /^-?-(?<key>[\w-]*?)(=(?<value>.*)|)$/.freeze
REG_FLAG = /^-?-(?<key>[\w-]*?)$/.freeze

git_repo = ARGV[0] if !ARGV.empty?
git_path = ARGV[1] if !ARGV.empty?

`git clone --bare #{git_repo.to_s} #{git_path.to_s};`
`cd #{git_path.to_s};`

all_tags_str = `git tag --list`
puts all_tags_str.to_s

all_tags = all_tags_str.split('\n')
all_tags.each do |block|
    puts block.to_s
end

`cd ..`
