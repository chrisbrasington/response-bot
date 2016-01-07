curl -s "http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml?query=${@:-<ZIPCODEHERE>}"|perl -ne '/<title>([^<]+)/&&printf "%s: ",$1;/<fcttext>([^<]+)/&&print $1,"\n"';
