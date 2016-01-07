# ruby-gmail-auto-responder
Ask gmail questions, get a response. Also can system commands.
There are a few default responses:

"What's up?" will respond with something.

"weather" will respond with response from weather.bat

"$" at beginning will invoke transaction command from [text-messaging-to-gnucash](https://github.com/chrisbrasington/text-messaging-to-gnucash) project. The actions invoked and response are driven from that project. Actions involved are adding a transaction to a SQLITE DB file and responding with a success/failure message.

Security:

Only a little bit, to be honest. At minimum, the Credential class only checks a specified inbox and the Listener class only responds to a specified address. Both accounts should be fully under your control. System commands (no parameters) are not directly invoked from the message being sent, but instead are interpreted by the message body in check-email.rb. System commands with parameters are much riskier and checked to against potentially malicious characters, and the email is rejected if deemed malicious. It's not fool proof, but since you can specify what email to listen to and how to respond to that message, coder discretion be advised. Read me [here](https://www.owasp.org/index.php/Command_Injection)

Sample secret.rb file:
```
class Credentials
    def self.email
        '~~~~EMAIL HERE~~~~@gmail.com'
    end 
    def self.password
        '~~~~PASSWORD HERE~~~~'
    end
    # timeout not yet accounted for in main code
    def self.oauth2_token
        '~~~~OAUTH2 TOKEN HERE~~~~'
    end
end
class Listener
    def self.email
        '~~~~EMAIL / PHONE SMS EMAIL HERE~~~~'
    end
end
```