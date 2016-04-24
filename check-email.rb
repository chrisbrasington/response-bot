#!/usr/bin/env ruby
require 'gmail'
require 'yaml'

def respond(gmail, email, message, subject_title)
    puts '----------------------------------'
    puts 'Responding to ' + email
    puts message

    gmail.deliver do
        to email
        subject subject_title
        body message
    end
	puts 'Sent'
    puts '----------------------------------'
end

def run
    # check once, run again on cronjob
    
    fullPath = "./"
    
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
                email.message.attachments.each do |a|                        
                    if File.extname(a.filename) == '.txt'
                        text = a.body.to_s
                        # avoid possible command line injection
                        text = text.split('\'')[0]  
                        if text.include? '\'' or text.include? ';' or text.include? '/'
                            email.read!
                            email.move_to("Ignore - Malicious")
                        elsif
                            if text == "status"
                                puts 'Asked for status.'
                                message = 'Feeling pretty great.' 
                                respond(gmail, settings['listener'], message, 'Status Report')
                                email.read!
                                #email.archive! is currently broken, labeling as SMS
                                email.move_to("SMS")
                            elsif text.downcase == 'weather'
                                puts 'Running weather script..'
                                command = fullPath+'weather.bat ' + settings['city']
                                weather = %x[#{command}]
                                respond(gmail, settings['listener'], weather, 'Weather')
                                email.read!
                                email.move_to("SMS")
                            elsif text.downcase == 'snow' or text.downcase == 'keystone'
                                puts 'Running Keystone snow report..'
                                command = fullPath+'keystone.bat'
                                snow = %x[#{command}]
                                respond(gmail, settings['listener'], snow, 'KeyStone Snow Report')
                                email.read!
                                email.move_to("SMS")
                            elsif text.index('$') == 0
                                puts 'Running transaction script..'
                                # note transaction command is driven from another project
                                # to log financial tranasctions to gnucash
                                # https://github.com/chrisbrasington/text-messaging-to-gnucash
                                command = 'transaction '
                                command += "'" + text + "'"
                                value = %x[#{command}]
                                
                                puts command
                                puts
                                puts value
                                
                                respond(gmail, settings['listener'], value, 'Transaction')
                                email.read!
                                email.move_to("SMS")
                            else
                                email.read!
                                email.move_to("Ignore")
                            end
                        end
                    end
                end
                               
                gmail.inbox.find(:unread).each do |email|
                    email.read!
                    email.move_to("Ignore")
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