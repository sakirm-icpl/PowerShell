Get-Date  # For display date and time
Get-Date -DisplayHint Date # For display only date
Get-Date -Format g # For display date and time on Shortcut
Get-Date -UFormat "%Y / %m / %d / %A / %Z" # For display date year/month/day day in word
$a = Get-Date
$a.ToUniversalTime() # To convert the current date and time to UTC
#set-date -date "06/08/2019 18:53" # For set date and time
Set-Date -Date (Get-Date).AddDays(5) # For see what is the date after 5 days
Set-Date -Adjust -0:15:0 -DisplayHint Time # To set the system time 15 minutes back.
