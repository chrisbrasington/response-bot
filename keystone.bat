curl -s "http://www.keystoneresort.com/rss/snowreport.aspx"| awk 'gsub(/.*<description>|<\/description>.*/,"") gsub("&lt;br/&gt;", ". ") gsub("New Snow in last ", "")'
