#!/usr/bin/env ruby
require 'gmail'
require 'yaml'
require 'awesome_print'


def respond(gmail, email, message, subject_title)
    puts '----------------------------------'
    puts 'Responding to ' + email
    puts message

    gmail.deliver do
        to email
        subject subject_title
        body message
        html_part do
            content_type 'text/html; charset=UTF-8'
            body "<p>#{message}</p>"
        end
    end
	puts 'Sent'
    puts '----------------------------------'
end

def run
    # check once, run again on cronjob
    
    fullPath = "/home/christopher/repo/response-bot/"
    
    # settings file
    settings = YAML.load_file(fullPath+'settings.yml')

    Gmail.connect!(settings['email'], settings['password']) do |gmail|
        if !gmail.logged_in?
            puts 'Failure to login.'
        else
            puts 'Successful login.'
            puts 'Checking inbox...'
            
            # notify if nothing to do
            foundMessage = false
            
            gmail.inbox.find(:unread, :from => settings['listener']).each do |email|
                foundMessage = true
                print 'Found email from ',settings['listener_name']
                puts
				
				if email.subject == 'transit'
					puts 'Transit request found.'
                    text = email.message.body.to_s.strip
                    
                    if text.start_with?('transit')
                        email.read!
                        
                        command = text
                        puts "Gathering response for (#{command})"
                        
                        value = %x[#{command}]

                        value = command + '<br><br>' + value

                        respond(gmail, settings['listener'], value, 'Transit')
                        email.move_to("SMS")
                    end                  
				end			
            end
            
            if not foundMessage
                puts "Nothing to do."
            end
            
            puts 'Logging out.'
            gmail.logout
        end  
    end
end

begin
    puts 'Beginning gmail checker.'
    run
rescue => exception
    puts 'In rescue - exiting.'
    puts exception
ensure
    puts 'Exiting.'
end   