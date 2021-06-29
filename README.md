# icinga-downtime script

This is an example on how to setup an automatic downtime in Icinga using scripts.

Currently only a PowerShell script is provided here.

## Icinga 2 config

You will need to create an API user to allow access to the downtime functionality.

```icinga2
object ApiUser "downtime" {
  password = "magicunicornpleasechangeme"

  permissions = [
      {
          permission = "actions/schedule-downtime"
          filter = {{ regex("^Windows", host.vars.os) }}
      }
  ]
}
```

Also see [Icinga 2 API permissions](https://icinga.com/docs/icinga-2/latest/doc/12-icinga2-api/#permissions).

## Windows

A script like this can be used to be set as shutdown script via GPO (group policy).

API and credentials can either be passed on command line, or set inside the script. The PowerShell script also contains an example to build a credential from string.

Some examples:

```powershell
$cred = Get-Credential;
.\icinga-downtime.ps1 -Api https://icinga.local:5665 -Credential $cred;
.\icinga-downtime.ps1 -SkipCertificateCheck;

.\icinga-downtime.ps1 -Duration 900;
.\icinga-downtime.ps1 -HostName "this-windows-host.fqdn" -Author "Windows" -Comment "Automatic shutdown downtime";
```

## License

Copyright (C) 2021 [NETWAYS GmbH](mailto:info@netways.de)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see [gnu.org/licenses](https://www.gnu.org/licenses/).
