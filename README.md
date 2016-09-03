# linux-bash-script-to-check-cpanel-server-domains-against-google-safe-browsing-db

+ Bash script to find last n cpanel account's names and check all its domains/subdomains/1stlevelsub-directories against Google safe browsing database.
+ Report bad domains to admin via e-mail

## Requirements ##

+ cPanel/WHM Linux server
+ Google Safe Browsing APIv3 key
+ SBLookup bash script from https://raw.githubusercontent.com/ivanra/sblookup/master/sblookup

## Installation ##

+ Create & enter new directory on your server
+ Download script from this repository
+ Download sblookup script from https://raw.githubusercontent.com/ivanra/sblookup/master/sblookup and chmod 700 it
+ Obtain APIv3 key from https://console.developers.google.com (create new project) and copy it inside my script
+ Update other variables in my script
+ Do a test run (on your risk) and possibly setup a cronjob (daily..)

SB API is said to have limit of 10K queries/day and 200 queries/second
