<#
.SYNOPSIS
    Icinga downtime script to easily create downtimes via the Icinga 2 API.
.DESCRIPTION
    Can be used on shutdown to create an automatic downtime for a few minutes.
.EXAMPLE
    $cred = Get-Credential;
    .\icinga-downtime.ps1 -Api https://icinga.local:5665 -Credential $cred;
    .\icinga-downtime.ps1 -SkipCertificateCheck;

    .\icinga-downtime.ps1 -Duration 900;
    .\icinga-downtime.ps1 -HostName "this-windows-host.fqdn" -Author "Windows" -Comment "Automatic shutdown downtime";
.LINK
https://github.com/NETWAYS/icinga-downtime-scripts
.NOTES
Copyright (C) 2021 NETWAYS GmbH <info@netways.de>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>
param (
    [String]$Api = "https://icinga.local:5665",
    [System.Management.Automation.PSCredential]$Credential,
    [String]$HostName,
    [String]$Author,
    [String]$Comment,
    [int]$Duration = 300,
    [String]$LogFile = "C:\Windows\Temp\icinga-downtime.log",
    [switch]$SkipCertificateCheck,
    [switch]$Debug
)

# set default credentials when you want
$DefaultUsername = "";
$DefaultPassword = "";

$UNIXEPOCH = [DateTime]::new(1970, 1, 1, 0, 0, 0, 0, [System.DateTimeKind]::Utc);

function Write-Log {
    param (
        [String]$Text
    )

    if ($Debug -or $LogFile -eq "") {
        Write-Host $Text;
    }

    if ($LogFile -ne "") {
        "[$(Get-Date -format "yyyy-MM-dd HH:mm:ss")] ${Text}" | Out-File $LogFile -Append
    }
}

function Write-DebugLog {
    param (
        [String]$Text
    )

    if ($Debug) {
        Write-Log $Text;
    }
}

function Build-UnixTimestamp {
    param (
        [datetime]$time
    )

    return [int64]($time.ToUniversalTime()-$UNIXEPOCH).TotalSeconds;
}

Write-Log "Starting downtime script"

# Set default credential
if ($Credential -eq $null -and $DefaultUsername -and $DefaultPassword) {
    $Credential = New-Object System.Management.Automation.PSCredential(
        $DefaultUsername,
        (ConvertTo-SecureString $DefaultPassword -AsPlainText -Force)
    );
}

# Set HostName when not passed
if ($HostName -eq "") {
    $computer = Get-CimInstance -Class Win32_ComputerSystem;

    $HostName = $computer.Name;

    if ($computer.Domain) {
        $HostName += "." + $computer.Domain;
    }

    # make lowercase
    $HostName = $HostName.ToLower()

    #Write-DebugLog "Computer Name is: ${HostName}";
}

# Set author when not passed
if (! $Author) {
    $Author = (Get-CimInstance -Class Win32_ComputerSystem).UserName;
}

# Set comment when not passed
if (! $Comment) {
    $Comment = "Automatic downtime initiated by " + $Author;
}

# Ensure TLS settings are improved - bad defaults in Windows
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls11,Tls12'

$headers = @{
    "Accept" = "application/json"
};

$start = Build-UnixTimestamp([datetime]::Now);
$end = $start + $Duration;

$data = @{
    "type"         = "Host"
    "host"         = $HostName
    "author"       = $Author
    "comment"      = $Comment
    "start_time"   = $start
    "end_time"     = $end
    "all_services" = $true
};

try {
    Write-DebugLog "Sending HTTP Request to: ${Api}/v1/actions/schedule-downtime";
    $body = (ConvertTo-Json -InputObject $data -Compress);
    Write-Log "Request body: ${body}";

    $result = Invoke-WebRequest `
        -Uri "${Api}/v1/actions/schedule-downtime" `
        -Method "POST" `
        -Body $body `
        -Credential $Credential `
        -ContentType "application/json" `
        -Headers $headers `
        -SkipCertificateCheck:$SkipCertificateCheck;
}
catch {
    if ($_.Exception.Response.StatusCode) {
        $status = $_.Exception.Response.StatusCode.value__;
        Write-Log "API responded with an error code=${status} - ${_}";
    } else {
        Write-Log "API request failed: $_";
    }
}

if ($result) {
    Write-Log "API returned: ${result}";
}

Write-Log "Finished downtime script";
