
using namespace System.Net.Sockets
using namespace System.Net.Security
using namespace System.Security.Cryptography.X509Certificates

# Define function
function ConvertFrom-X509Certificate {
    param(
        [Parameter(ValueFromPipeline)]
        [X509Certificate2]$Certificate
    )

    process {
        @(
            '-----BEGIN CERTIFICATE-----'
            [Convert]::ToBase64String(
                $Certificate.Export([X509ContentType]::Cert),
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
    Try {
        $tcpClient = [TcpClient]::new($endpoint.dnsName, $endpoint.port)
    }
    Catch {
        $tempObject = New-Object PSObject
        $tempObject | Add-Member -MemberType NoteProperty -Name dnsName -Value $endpoint.dnsName
        $tempObject | Add-Member -MemberType NoteProperty -Name port -Value $endpoint.port
        $tempObject | Add-Member -MemberType NoteProperty -Name connectionState -Value "Failed"
        $tempObject | Add-Member -MemberType NoteProperty -Name validUntil -Value "Unknown"
        $tempObject | Add-Member -MemberType NoteProperty -Name issuer -Value "Unknown"
        $tempObject | Add-Member -MemberType NoteProperty -Name sans -Value "Unknown"
        $certResults += $tempObject
        Continue
    }

    Try {
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
    $tempObject = New-Object PSObject
    $tempObject | Add-Member -MemberType NoteProperty -Name dnsName -Value $endpoint.dnsName
    $tempObject | Add-Member -MemberType NoteProperty -Name port -Value $endpoint.port
    $tempObject | Add-Member -MemberType NoteProperty -Name connectionState -Value "Successful"
    $tempObject | Add-Member -MemberType NoteProperty -Name validUntil -Value $result.NotAfter
    $tempObject | Add-Member -MemberType NoteProperty -Name issuer -Value $result.IssuerName.Name
    $tempObject | Add-Member -MemberType NoteProperty -Name sans -Value ($result.Extensions | Where-Object {$_.Oid.FriendlyName -eq "Subject Alternative Name"}).format($true)
    $certResults += $tempObject
}   

$certResults | Export-Csv .\outputs.csv -UseCulture -NoTypeInformation
