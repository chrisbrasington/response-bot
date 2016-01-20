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

def loop
    # check every 10 seconds
    counterSleep = 10
    counterLoop = 0
    
    # logout/login to refresh session (and avoid timeout)
    # every 1 minute (6 attempts)
    sessionRefresh = 6
    
    # settings file
    settings = YAML.load_file('settings.yml')

    Gmail.connect!(settings['email'], settings['password']) do |gmail|
        if !gmail.logged_in?
            puts 'Failure to login'
        else
            puts 'Successful login'
            print '  Check interval every ', counterSleep, ' seconds.'
            puts
            print '  Re-authenticate gmail session every ', sessionRefresh*counterSleep, ' seconds.'
            puts
            
            while true
                print 'Checking inbox (', counterLoop+1, ')...'
                puts
                counterLoop += 1
                if counterLoop >= sessionRefresh
                    counterLoop = 0 # reset counter
                    gmail.logout
                    gmail = Gmail.connect!(settings['email'], settings['password'])
                    if gmail.logged_in?
                        puts 'Refresh: re-authentication gmail session.'
                    elsif
                        puts 'Failure to login.'
                        break
                    end
                end
                gmail.inbox.find(:unread, :from => settings['listener']).each do |email|
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
                                    command = './weather.bat ' + settings['city']
                                    weather = %x[#{command}]
                                    respond(gmail, settings['listener'], weather, 'Weather')
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
                sleep counterSleep
            end
        end  
    end
end

while true
    begin
        puts 'Beginning gmail listener.'
        loop
    rescue => exception
        puts 'In rescue'
        puts exception
    ensure
        begin
            puts 'Hit Ensure (due to failure) - sleeping for half a minute.'
            sleep 30
        ensure
            break #allow 2 force breaks (CTRL+C) to stop the program
        end
    end   
end