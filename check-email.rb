#!/usr/bin/env ruby
load 'secret.rb'
require 'gmail'

def respond(gmail, email, message)
    puts 'Responding to ' + email
    puts message

    gmail.deliver do
        to email
        subject ""
        body message
    end
end


Gmail.connect!(Credentials.email, Credentials.password) do |gmail|
    if !gmail.logged_in?
        puts 'Failure to login'
    else
        while true
            if gmail.inbox.count > 0
                emails = gmail.inbox.emails(:unread, :from => Listener.phone)
                print emails.count, " emails from: ", Listener.phone
                puts
                emails.each do |email|
                    email.message.attachments.each do |a|
                        if File.extname(a.filename) == '.txt'
                            text = a.body.to_s
                            puts text
                            if text == "What's up?"
                                message = 'Feeling kinda bored ' #+ Time.now.to_s
                                respond(gmail, Listener.phone, message)
                                email.read
                                #email.archive! is currently broken, labeling as SMS
                                email.move_to("SMS")
                            elsif text == 'weather'
                                command = './weather.bat ' + default_city
                                weather = %x[#{command}]
                                respond(gmail, Listener.phone, weather)
                                email.read
                                email.move_to("SMS")
                            elsif text.index('$') == 0
                                # note transaction command is driven from another project
                                # to log financial tranasctions to gnucash
                                # https://github.com/chrisbrasington/text-messaging-to-gnucash
                                command = 'transaction '
                                command += "'" + text + "'"
                                value = %x[#{command}]
                                respond(gmail, Listener.phone, value)
                                email.read
                                email.move_to("SMS")
                            else
                                email.read
                                email.move_to("Ignore")
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
                print "0 emails from: ", Listener.phone
                puts
            end
            sleep 10
        end
    end  
end

