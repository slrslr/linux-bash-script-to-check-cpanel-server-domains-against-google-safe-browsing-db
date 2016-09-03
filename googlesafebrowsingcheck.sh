# Script to find last n cpanel account names and check all its domains/subdomains/1stlevelsub-directories against google safe browsing database.
# Report bad domains to admin via e-mail
# run this for example daily as a cronjob
# SafeBrowsing API key can be obtained by creating new project at https://console.developers.google.com
# SB API is said to have limit of 10K queries/day and 200 queries/second
# Download and place "sblookup" script (https://raw.githubusercontent.com/ivanra/sblookup/master/sblookup) in same directory like this script and chmod 700 it

adminmail=YOU@gmail.com
v3googlesafebrowsingapikey=YOURAPIKEYHERE
good_message="ok"
nodata_message="304"
numberoflastcpanels="200" # Number of newest cpanel accounts (including suspended ones) to include into checking process.
sleeptime="2" # Number of seconds to wait before each domain/subdomain check to prevent google ban?

thisscriptdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# empty temporary domain list file
> $thisscriptdir/last_cpanel_domains

# DISCOVER LAST CPANEL USERNAMES - add n log entries containing newest cpanel usernames into file
tail -n $numberoflastcpanels /var/cpanel/accounting.log | grep CREATE > /tmp/lastcpanelslog
ls -A1 /var/cpanel/suspended > /tmp/suspendedcpanels
grep -v -F -f /tmp/suspendedcpanels /tmp/lastcpanelslog > /tmp/lastcpanels

# CREATE LIST OF CPANEL USER'S DOMAINS (dn) AND SITE SUBDIRECTORIES (subdir)
while read logline;do
cpusr=$(echo "$logline" | tail -c-9)
for dn in $(grep ": $cpusr" /etc/userdomains | cut -d: -f1);do
echo "$dn" >> $thisscriptdir/last_cpanel_domains
for subdir in $(ls -A1 /home/$cpusr/public_html|grep -vE "\.|cgi-bin");do
echo "$dn/$subdir" >> $thisscriptdir/last_cpanel_domains
done
done
done < /tmp/lastcpanels

# LOOP THRU DOMAIN LIST (domain.tld or domain.tld/subdir/) TO DISCOVER GOOGLE SAFE BROWSING STATUS
while read url;do
sleep $sleeptime
google_sb_output=$(echo "$url/"|$thisscriptdir/sblookup -a "$v3googlesafebrowsingapikey")
#google_sb_output=$(curl --silent --max-time 20 https://www.google.com/transparencyreport/safebrowsing/diagnostic/?#url=$url)

# Send report if no good message
echo "Lookup for $url finished with status $google_sb_output."
if [[ "$google_sb_output" != *"$good_message"* || "$google_sb_output" == *"$nodata_message"* ]];then
domain=$(echo "$url"|awk -F/ '{print $1}')
cpusr=$(/scripts/whoowns $domain)
echo "Google Safe Browsing for the http://$url (user: $cpusr) have not returned any known result ($good_message OR $nodata_message).
Site may be maicious or other error. GSB returned this: $google_sb_output
Safe browsing report: https://www.google.com/transparencyreport/safebrowsing/diagnostic/?#url=$url

/home/$cpusr/public_html/ of the cpanel user $cpusr (25 last modiffied entries):
$(find /home/$cpusr/public_html -type f -iname "*.php"|grep -vE "wp-"|head -n 50)

This is email from $(hostname) $thisscriptdir/ based script" | mail -s "Google Safe Browsing at $(hostname): Possible malicious website" $adminmail
fi
done < $thisscriptdir/last_cpanel_domains
echo "Good, the $thisscriptdir/ script finished / was not killed." | mail -s "GSB script finished" $adminmail
# end
