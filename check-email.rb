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
                            email.read!
                            #email.archive! is currently broken, labeling as SMS
                            email.move_to!("SMS");
                        elsif text == 'weather'
                            weather = %x[./weather.bat Denver]
                            respond(gmail, Listener.phone, weather)
                            email.read!
                            #email.archive! is currently broken, labeling as SMS
                            email.move_to!("SMS");
                        elsif text.index('$') == 0
                            command = 'transaction '
                            command += "'" + text + "'"
                            value = %x[#{command}]
                            respond(gmail, Listener.phone, value)
                            email.read!
                            email.move_to!("SMS");
                        end
                    end
                end
            end
        else
            print "0 emails from: ", Listener.phone
            puts
        end
    end  
end

