#!/usr/bin/env ruby

# usage: git_submodule_script.rb < /tmp/junk.3
#
# git co v147-hotfixes2
# git submodule update
# git submodule | awk '{print $2,$1}' > /tmp/junk.1
# git co v147-hotfixes3
# git submodule update
# git submodule | awk '{print $2,$1}' > /tmp/junk.2
# join /tmp/junk.{1,2} > /tmp/junk.3





repos = {}

STDIN.read.split("\n").each do |line|
  (dir, sha1, sha2) = line.split
  if sha1 != sha2
    repos[dir]=[sha1,sha2]
  end
end

repos.each do |repo, shas|
  curdir = Dir.getwd
  puts "submodule: #{repo}"
  Dir.chdir(repo)
  puts `git lg --pretty="%h %s" #{shas[1]..shas[0]}`
  Dir.chdir(curdir)
end
