# Script to check certificate expiration and alert out

# Get the current directory and assign to a variable

$CurrDir = (Get-Item -Path ".\" -Verbose).FullName

# Get the computer name

$ComputerName = (Get-Childitem env:computername).Value

# Dump information from all CAs. This caters for using multiple issuing servers/authorities.

certutil -view -config "ca1.contoso.com\CA Name" csv > ".\CertDetails.csv"
certutil -view -config "ca2.contoso.com\CA Name" csv >> ".\CertDetails.csv"
certutil -view -config "ca3.contoso.com\CA Name" csv >> ".\CertDetails.csv"

# Store information from CAs in a variable

$CertList = Import-CSV .\CertDetails.csv -UseCulture

###################################################################################################

# Build the HTML for the email which'll be generated

$HTMLHead="<html>`n`r
<head>`n`r
<meta http-equiv=`"Content-Type`" content=`"text/html; charset=utf-8`">`n`r
</head>`n`r
<style>`n`r
BODY{font-family: Calibri; font-size: 11pt;}`n`r
H1{font-size: 16px;}`n`r
H2{font-size: 14px;}`n`r
H3{font-size: 12px;}`n`r
TABLE{border: 1px solid black; border-collapse: collapse; font-size: 11pt;}`n`r
TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}`n`r
TD{border: 1px solid black; padding: 5px; }`n`r
td.green{background: #7FFF00;}`n`r
td.orange{background: #FFE600;}`n`r
td.red{background: #FF0000; color: #ffffff;}`n`r
td.info{background: #85D4FF;}`n`r
</style>`n`r`n`r
<body>`n`r"

# Introduction part of the email body

$HTMLIntro="Hi,<br /><br />`n`r
The table below shows certificates which will expire in the forthcoming 60 days that were issued by authorities joined to the contoso.com domain.<br /><br />`n`r
<ul>`n`r
<li>If the certificate is still required, the system owner should generate a CSR and request a new certificate.</li>`n`r
<li>If the certificate is no longer required, it should be revoked.</li>`n`r
</ul>`n`r"

$HTMLOutro="</table>`n`r
<br /><br />Yours sincerely,<br /><br />`n`r
The Monitoring Script on " + $ComputerName + "`n`r
<br /><br /><br />`n`r
<ul><i>`n`r
<li>The script that generated this mail resides in " + $CurrDir + " on " + $ComputerName + ".</li>`n`r
<li>Email settings can be modified by changing " + $CurrDir + "\Settings.xml on " + $ComputerName + ".</li>`n`r
<li>Source for this script can be found in GIT.</li>`n`r
</i></ul>`n`r"

# Define the HTML footer
$HTMLFoot="`n`r
</body>`n`r
</html>`n`r"

### Start building the email body ###
# Add the HTML header
$Body = $htmlhead

# Add the introduction
$Body += $HTMLIntro

# Start building the table
$Body += "`n`r<table>`n`r<colgroup><col><col><col><col><col><col><col><col></colgroup>"
$Body += "<tr><th>Common Name</th><th>Days Until Expiry</th><th>Expiry Date</th><th>Template</th><th>Original Requestor</th><th>Subject Key Identifier</th></tr>`n"

###################################################################################################

# Get the current date and time

$Now = Get-Date

# Loop through the certificate list and get the information we care about
# Exclude certificate types which we don't care about

$StartRow = "`n`r<tr>"
$EndRow = "</tr>`n`r"

ForEach ($Certificate in $CertList) {
    If (($Certificate."Certificate Expiration Date" -ne "EMPTY") -and `
        ($Certificate."Request Common Name" -ne "EMPTY") -and `
        ($Certificate."Request Disposition" -eq "20 -- Issued") -and `
        ($Certificate."Certificate Template" -notmatch "Computer Autoenrollment") -and `
        ($Certificate."Certificate Template" -notmatch "CAExchange") -and `
        ($Certificate."Certificate Template" -notmatch "User") -and `
        ($Certificate."Certificate Template" -notmatch "EFS") -and `
        ($Certificate."Certificate Template" -notmatch "Machine") -and `
        ($Certificate."Certificate Template" -notmatch "ClientAuth") -and `
        ($Certificate."Certificate Template" -notmatch "Kerberos Authentication"))
        {
            $DaysUntilExpiry = (New-TimeSpan -Start $Now -End $Certificate."Certificate Expiration Date").Days

            If (($DaysUntilExpiry -gt 30) -and ($DaysUntilExpiry -le 60)) {
                $CellColour = "green"
                } ElseIf (($DaysUntilExpiry -gt 10) -and ($DaysUntilExpiry -le 30)) {
                $CellColour = "orange"
                } ElseIf (($DaysUntilExpiry -ge -30) -and ($DaysUntilExpiry -le 10)) {
                $CellColour = "red"
                } Else {
                $CellColour = "green"
                }

            $CertificateTemplate = ($Certificate."Certificate Template")
            If ($CertificateTemplate -match "1.3.6.1") {
                $CertificateTemplate = ($CertificateTemplate -Split " ",2)[1]
                }

            If (($DaysUntilExpiry -ge "-30") -and ($DaysUntilExpiry -le "60")) {
                Write-Host ($Certificate."Request Common Name" + "," + `
                $DaysUntilExpiry + "," + `
                $Certificate."Certificate Expiration Date" + "," + `
                $CertificateTemplate + "," +`
                $Certificate."Requester Name")

                $Body += $StartRow
                $Body += "<td>" + $Certificate."Request Common Name" + "</td>"
                $Body += "<td class=`"" + $CellColour + "`">" + $DaysUntilExpiry + "</td>"
                $Body += "<td>" + $Certificate."Certificate Expiration Date" + "</td>"
                $Body += "<td>" + $CertificateTemplate + "</td>"
                $Body += "<td>" + $Certificate."Requester Name" + "</td>"
                $Body += "<td>" + $Certificate."Issued Subject Key Identifier" + "</td>"
                $Body += $EndRow

                }
        }
    }

$Body += $HTMLOutro
$Body += $HTMLFoot

$Body > .\Body.html


# Import Settings.xml config file
[xml]$ConfigFile = Get-Content ".\Settings.xml"

# Send the email message

# The following line forces an message to be sent irrespective of service status. Remove it/comment it out for
# messages only to be sent when there is a problem

$SendAlertEmail = "1"

If ($SendAlertEmail -eq "1") {
    $smtpsettings = @{
        To = $ConfigFile.Settings.EmailSettings.MailTo
        From = $ConfigFile.Settings.EmailSettings.MailFrom
        SmtpServer = $ConfigFile.Settings.EmailSettings.SMTPServer
        }
    $Now = Get-Date
    $messageSubject = "Certificate expiry report at " + ($Now.DateTime)
    
    $emailSmtpServer = $ConfigFile.Settings.EmailSettings.SMTPServer
    $emailSmtpServerPort = $ConfigFile.Settings.EmailSettings.SMTPPort
    
    $emailMessage = New-Object System.Net.Mail.MailMessage
    $emailMessage.From = $ConfigFile.Settings.EmailSettings.MailFrom
    
    ForEach ($MailAddress in $ConfigFile.Settings.EmailSettings.MailTo) {
        $emailMessage.To.Add($MailAddress)
        }
    $emailMessage.Subject = $messageSubject
    $emailMessage.IsBodyHtml = $true
    $emailMessage.Body = $Body
    
    $SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
    $SMTPClient.EnableSsl = $false
    $SMTPClient.UseDefaultCredentials = $false
    $SMTPClient.Send($emailMessage)
    }
