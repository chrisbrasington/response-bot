# response-bot (ruby gmail responder)
Ask gmail questions, get a response. Also can system commands.

#### Default responses:

"status" will respond with something.

"weather" will respond with response from weather.bat

"snow" will respond with Keyston Snow Report from keystone.bat

"$" at beginning will invoke transaction command from [text-messaging-to-gnucash](https://github.com/chrisbrasington/text-messaging-to-gnucash) project. The actions invoked and response are driven from that project. Actions involved are adding a transaction to a SQLITE DB file and responding with a success/failure message.

#### Todo:

I would like to expand functionality to [Denver's RTD transit live-data](http://www.rtd-denver.com/gtfs-developer-guide.shtml).

#### Security:

An "ignore all but this email" gmail filter is a good idea, to reject all other emails from reaching the inbox (thus being ignored, but not spoofing proof). It looks like from:(-{EMAIL_TO_LISTEN_TO}).

The settings.yml file, might want to hide that. Additionally, the settings.yml file sets the program to only checks a specified inbox and the listener only responds to a specified address. Both accounts should be fully under your control. System commands (no parameters) are not directly invoked from the message being sent, but instead are interpreted by the message body in check-email.rb. System commands with parameters are much riskier and checked to against potentially malicious characters, and the email is rejected if deemed malicious. It's not fool proof, but since you can specify what email to listen to and how to respond to that message, coder discretion be advised. Read me [here](https://www.owasp.org/index.php/Command_Injection)

Sample settings.yml file:
```
city: WEATHER_CITY
email: EMAIL_INBOX
password: EMAIL_PASSWORD
listener: EMAIL_SMS_TO_LISTEN_AND_RESPOND_TO
listener_name: STRING_NAME_HERE
```

Sample output:
```
~/repo/response-bot $ ./check-email.rb 
Beginning gmail listener.
Successful login
  Check interval every 10 seconds.
  Re-authenticate gmail session every 60 seconds.
Checking inbox (1)...
Checking inbox (2)...
Checking inbox (3)...
Found email from Chris' Phone
Asked for status.
----------------------------------
Responding to {EMAIL_HERE}
Feeling pretty great.
Sent
----------------------------------
Checking inbox (4)...
Checking inbox (5)...
Found email from Chris' Phone
Running weather script..
----------------------------------
Responding to {EMAIL_HERE}
Tonight: Partly cloudy in the evening then becoming mostly cloudy. Lows 23 to 29.
Wednesday: Mostly cloudy. Highs 43 to 49.
Wednesday Night: Mostly cloudy with a 20 percent chance of snow. Lows in the lower 20s. Northwest winds 10 to 15 mph.
Thursday: Mostly sunny. Highs near 40.
Thursday Night: Mostly clear. Lows 17 to 25.
Sent
----------------------------------
Checking inbox (6)...
Refresh: re-authentication gmail session.
Checking inbox (1)...
Checking inbox (2)...
Found email from Chris' Phone
Running transaction script..
transaction '$0.00,TEST,Dining'

Success: 2016-01-19 18:20:12 ($0.00) "TEST" Expenses:Dining from Liabilities:Credit Card
----------------------------------
Responding to {EMAIL_HERE}
Success: 2016-01-19 18:20:12 ($0.00) "TEST" Expenses:Dining from Liabilities:Credit Card
Sent
----------------------------------
^CHit Ensure (due to failure) - sleeping for half a minute.
^C
```
