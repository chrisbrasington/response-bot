#!/usr/bin/env ruby
require 'gmail'
require 'yaml'

settings = YAML.load_file('settings.yml')

def respond(gmail, email, message)
    puts 'Responding to ' + email + '\n'
    puts message

    gmail.deliver do
        to email
        subject ""
        body message
    end
	
	puts 'Sent'

end

Gmail.connect!(settings['email'], settings['password']) do |gmail|
    if !gmail.logged_in?
        puts 'Failure to login'
    else
        while true
            if gmail.inbox.count > 0
                emails = gmail.inbox.emails(:unread, :from => settings['listener'])
                print emails.count, " emails from: ", settings['listener']
                puts
                emails.each do |email|
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
                                    message = 'Feeling pretty great.' 
                                    respond(gmail, settings['listener'], message)
                                    email.read!
                                    #email.archive! is currently broken, labeling as SMS
                                    email.move_to("SMS")
                                elsif text.downcase == 'weather'
                                    command = './weather.bat ' + settings['city']
                                    weather = %x[#{command}]
                                    respond(gmail, settings['listener'], weather)
                                    email.read!
                                    email.move_to("SMS")
                                elsif text.index('$') == 0
                                    # note transaction command is driven from another project
                                    # to log financial tranasctions to gnucash
                                    # https://github.com/chrisbrasington/text-messaging-to-gnucash
                                    command = 'transaction '
                                    command += "'" + text + "'"
                                    value = %x[#{command}]
                                    
                                    puts command
                                    puts
                                    puts value
                                    
                                    respond(gmail, settings['listener'], value)
                                    email.read!
                                    email.move_to("SMS")
                                else
                                    email.read!
                                    email.move_to("Ignore")
                                end
                            end
                        end
                    end
                end
                
                emails = gmail.inbox.emails(:unread)
                    if emails.count > 0
                    print "ignoring ", emails.count, " other email(s)"
                    puts
                    emails.each do |email|
                        email.read!
                        email.move_to("Ignore")
                    end
                end
            else
                print "0 emails from: ", settings['listener'] 
                puts
            end
            sleep 10
        end
    end  
end

