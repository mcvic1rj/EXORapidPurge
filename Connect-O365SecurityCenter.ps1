function Connect-O365SecurityCenter {
    param(
        [pscredential]$Credential,
        [boolean]$UseMFA = $true
    )
    try {
        if ($UseMFA) {
            $EXOMFAModulePath = $((Get-ChildItem -ErrorAction Stop -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse).FullName |
                    Where-Object { $_ -notmatch "_none_" } |
                    Select-Object -First 1)
            Import-Module $EXOMFAModulePath -ErrorAction Stop
            $O365SecuritySession = New-ExoPSSession -UserPrincipalName $Credential.UserName -ErrorAction Stop -ConnectionUri 'https://ps.compliance.protection.outlook.com/PowerShell-LiveId'
        }
        else {
            $O365SecuritySession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection
        }
        Import-Module (Import-PSSession $O365SecuritySession -AllowClobber ) -Global

    }
    catch {
        Write-Error $_
    }
}
