#!/usr/bin/env ruby
#
# usage: github_2_ldif
#
# reads from STDIN and outputs LDIF
#
#   e.g. curl -q -H "Authorization: token 3cccdcc1d16bd88f4fa8xxxxx" https://api.github.com/users/amannamedsmith |
#      jq '{login, id, name}' |
#      github_2_ldif password
#
# output is LDIF-format user
#
# dn: uid=eff,ou=Users,dc=cf-app,dc=com
# uid: eff
# cn: Frank Eff
# sn: Eff
# objectClass: inetOrgPerson
# objectClass: posixAccount
# userPassword: p@ssw0rd
# uidNumber: 555555
# gidNumber: 555555
# loginShell: /bin/bash
# homeDirectory: /home/eff

github_id="joker"
full_name="King Tut"
uid_number="666"
surname="Tut"
password=ARGV.first

STDIN.read.split("\n").each do |a|
   if a =~ /login/
     a.gsub!('  "login": "','')
     a.gsub!('",','')
     github_id=a
   end
   if a =~ /"name"/
     full_name=a.gsub('  "name": "','').gsub('"','')
     surname=full_name.split.last
   end
   if a =~ /"id"/
     uid_number=a.gsub('  "id": ','').gsub(',','')
   end
end

puts "dn: uid=#{github_id},ou=Users,dc=cf-app,dc=com\n"
puts "uid: #{github_id}\n"
puts "cn: #{full_name}\n"
puts "sn: #{surname}"
puts "objectClass: inetOrgPerson\n"
puts "objectClass: posixAccount\n"
puts "uidNumber: #{uid_number}\n"
puts "gidNumber: #{uid_number}\n"
puts "loginShell: /bin/bash\n"
puts "homeDirectory: /home/#{uid_number}\n"
puts "password: #{password}"
