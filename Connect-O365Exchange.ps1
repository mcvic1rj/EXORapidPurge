function Connect-O365Exchange {
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
            $EXOSession = New-ExoPSSession -UserPrincipalName $Credential.UserName -ErrorAction Stop
        }
        else {
            $EXOSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection
        }
        Import-Module (Import-PSSession $EXOSession -AllowClobber -ErrorAction Stop) -Global
    }
    catch {
        Write-Error $_
    }
}
