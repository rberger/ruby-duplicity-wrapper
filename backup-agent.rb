#!/usr/bin/ruby
#
# backups.rb remote agent
# SjG <samuel@1969web.com>
# $Id: backup-agent.rb,v 1.3 2007/03/08 23:40:24 samuel Exp $
#

require 'net/smtp'

version = 0.1
version_date = "2 February 2007"
verbose = false
#
#-------------------------------------------------------------------------
# edit these as you see fit
legal_commands = [
	'timestamp',
	'date',
	'rdiff-backup',
	'duplicity',
	'mysqldump',
	'pg_dump',
	'pg_dumpall'
	]

# illegal commands - these strings will get removed even
# if they're parameters to another command
illegal_commands = ['rm','su']

# illegal substrings - these substrings will get removed
# from commands or parameters
illegal_substrings = [';']

#-------------------------------------------------------------------------
# want to receive email when hackers are banging at the door? Change the
# next line to "true" and set your server details
email_errors = false
alert_to = 'you@yourdomain.com'
alert_from = 'backups@yourdomain.com' # this can be a comma-delimited list
email_subject = 'Backup Agent Error!'
smtp_server='smtp.yourdomain.com'
smtp_helo_domain=nil
smtp_user=nil
smtp_password=nil
#-------------------------------------------------------------------------

orig_command = ENV['SSH_ORIGINAL_COMMAND']
illegal_substrings.each { |pattern| orig_command =
	orig_command.gsub(/#{pattern}/, "") }

command_list = orig_command.split(' ')

if legal_commands.find{|legal| command_list[0]==legal} != nil
	puts "ok: #{command_list[0]}" if verbose
	clean = command_list.map do
		 |param|
		 param unless illegal_commands.find{|illegal| param==illegal} != nil
	end

	if clean[0] == 'timestamp'
		begin
			fout = File.open("#{clean[1]}/backup-metadata.txt", "w")
			fout.puts("#{clean[2]}")
		rescue
			puts "ERROR! "+$!
		ensure
			fout.close unless fout.nil?
		end
	else
		runstring = clean.join(" ")
		puts runstring if verbose
		exec runstring
	end
else
	if email_errors
		theMessage = "From: #{alert_from}\n" +
			"To: #{alert_to}\n" +
			"Subject: #{email_subject}\n\n" +
			"Illegal command received by #{$0}:\n"
		ENV.each{|key,val| theMessage+= "#{key} = #{val}\n"}
		Net::SMTP.start(smtp_server||'localhost', 25,
			smtp_helo_domain||'localhost.localdomain',
			smtp_user||nil, smtp_password||nil, :login) do |smtp|
  				smtp.send_message theMessage, alert_from, alert_to.split(%r{,\s*})
  		end
  	end

end
