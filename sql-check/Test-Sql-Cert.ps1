using namespace System.Net.Sockets
using namespace System.Net.Security
using namespace System.Security.Cryptography.X509Certificates

# Define variables
$outputFile = ("output_" + (Get-Date -Format ddMMyyyy_HHmmss) + ".csv")
$inputFile = (".\endpoints.csv")

# Define function
function ConvertFrom-X509Certificate {
    param(
        [Parameter(ValueFromPipeline)]
        [X509Certificate2]$certificate
    )

    process {
        @(
            '-----BEGIN CERTIFICATE-----'
            [Convert]::ToBase64String(
                $certificate.export([X509ContentType]::Cert),
                [Base64FormattingOptions]::InsertLineBreaks
            )
            '-----END CERTIFICATE-----'
        ) -join [Environment]::NewLine
    }
}

# Import list of endpoints to test from CSV
$endpoints = Import-Csv .\endpoints.csv -UseCulture
$certResults = @()

# Loop through endpoints, performing TLS handshake
ForEach ($endpoint in $endpoints) {
    $tempObject = $null
    Try {
        Write-Host "Attempting creation of socket to $($endpoint.dnsName)"
        $listening = (New-Object System.Net.Sockets.TcpClient).ConnectAsync($endpoint.dnsName, $endpoint.port).Wait(500)
        If (-Not $listening) {
            $tempObject = New-Object PSObject
            $tempObject | Add-Member -MemberType NoteProperty -Name dnsName -Value $endpoint.dnsName
            $tempObject | Add-Member -MemberType NoteProperty -Name port -Value $endpoint.port
            $tempObject | Add-Member -MemberType NoteProperty -Name connectionState -Value "Failed"
            $tempObject | Add-Member -MemberType NoteProperty -Name subject -Value "Unknown"
            $tempObject | Add-Member -MemberType NoteProperty -Name sans -Value "Unknown"
            $tempObject | Add-Member -MemberType NoteProperty -Name validUntil -Value "Unknown"
            $tempObject | Add-Member -MemberType NoteProperty -Name daysToExpiry -Value "Unknown"
            $tempObject | Add-Member -MemberType NoteProperty -Name issuer -Value "Unknown"
            $tempObject | Add-Member -MemberType NoteProperty -Name description -Value $endpoint.description
            $certResults += $tempObject
            Continue
        }
        Write-Host "Finished trying creation of socket"
        
    }
    Catch {
        $tempObject = New-Object PSObject
        $tempObject | Add-Member -MemberType NoteProperty -Name dnsName -Value $endpoint.dnsName
        $tempObject | Add-Member -MemberType NoteProperty -Name port -Value $endpoint.port
        $tempObject | Add-Member -MemberType NoteProperty -Name connectionState -Value "Failed"
        $tempObject | Add-Member -MemberType NoteProperty -Name subject -Value "Unknown"
        $tempObject | Add-Member -MemberType NoteProperty -Name sans -Value "Unknown"
        $tempObject | Add-Member -MemberType NoteProperty -Name validUntil -Value "Unknown"
        $tempObject | Add-Member -MemberType NoteProperty -Name daysToExpiry -Value "Unknown"
        $tempObject | Add-Member -MemberType NoteProperty -Name issuer -Value "Unknown"
        $tempObject | Add-Member -MemberType NoteProperty -Name description -Value $endpoint.description
        $certResults += $tempObject
        Continue
    }

    Try {
        $tcpClient = [TcpClient]::new($endpoint.dnsName, $endpoint.port)
        $tlsClient = [SslStream]::new($tcpClient.GetStream())
        $tlsClient.AuthenticateAsClient($endpoint.dnsName)

        If ($As -eq 'Base64') {
            #return $tlsClient.RemoteCertificate |ConvertFrom-X509Certificate
            $result = $tlsClient.RemoteCertificate |ConvertFrom-X509Certificate
        }
    
        $result = $tlsClient.RemoteCertificate -as [X509Certificate2]
    }
    Finally {
        If ($tlsClient -is [IDisposable]) {
        $tlsClient.Dispose()
        }
    }

    $daysToExpiry = ($result.NotAfter - (Get-Date)).days

    $tempObject = New-Object PSObject
    $tempObject | Add-Member -MemberType NoteProperty -Name dnsName -Value $endpoint.dnsName
    $tempObject | Add-Member -MemberType NoteProperty -Name port -Value $endpoint.port
    $tempObject | Add-Member -MemberType NoteProperty -Name connectionState -Value "Successful"
    $tempObject | Add-Member -MemberType NoteProperty -Name subject -Value $result.subject.Split(",")[0].split("`=")[1]
    $tempObject | Add-Member -MemberType NoteProperty -Name sans -Value ($result.Extensions | Where-Object {$_.Oid.FriendlyName -eq "Subject Alternative Name"}).format($true)
    $tempObject | Add-Member -MemberType NoteProperty -Name validUntil -Value $result.NotAfter
    $tempObject | Add-Member -MemberType NoteProperty -Name daysToExpiry -Value $daysToExpiry
    $tempObject | Add-Member -MemberType NoteProperty -Name issuer -Value $result.IssuerName.Name
    $tempObject | Add-Member -MemberType NoteProperty -Name description -Value $endpoint.description
    $certResults += $tempObject
}   

$certResults | Export-Csv $outputFile -UseCulture -NoTypeInformation
