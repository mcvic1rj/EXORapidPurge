# EXORapidPurge
The code herein can be used to create Compliance searches in a faster manner allowing security teams to respond and re-mediate phishing messages faster. 

This shaves time off of compliance searches by:
* Targetting only the recipients instead of whole tenants
* Allowing one to build a search completely from PowerShel
* Covers all permutations that your tenant recieved

This can be sped up even faster by only targeting recipients that the message was listed as Delivered.

## Process for using this
1. Import the 4 files
    ```powershell
    cd EXORapidPurge\
    . .\Connect-O365Exchange.ps1
    . .\Connect-O365SecurityCenter.ps1
    . .\Get-MessageTraceAllMessages.ps1
    . .\New-PhishSearchFromMT.ps1
    ```

2. Connect to Office 365 EXO and Security Center

    Using MFA
    ```powershell
    Connect-O365Exchange
    Connect-O365SecurityCenter
    ```

    Without MFA
    ```powershell
    $O365Cred=Get-Credential
    Connect-O365Exchange -Credential $O365Cred -UseMFA $false
    Connect-O365SecurityCenter -Credential $O365Cred -UseMFA $false
    ```
3. Create a search targetting the phishing message and save it to a variable.
    Available filters:
    * StartDate/EndDate: Defaults to the past week
    * FromIP 
    * RecipientAddress
    * SenderAddress
    * Status

    All messages from a specific IP
    ```powershell
    $phish=Get-MessageTraceAllMessages -FromIP 192.168.1.1 -RecipientAddress "*@mydomain.com"
    ```

    All messages from a specific sending domain
    ```powershell
    $phish=Get-MessageTraceAllMessages -SenderAddress "*@badguys.com" -RecipientAddress "*@mydomain.com"
    ```

    All messages from a specific sender
    ```powershell
    $phish=Get-MessageTraceAllMessages -SenderAddress "ryan@badguys.com" -RecipientAddress "*@mydomain.com"
    ```

    Note: If you have to purge a subset of the messages returned by the above commands, you can filter them out. I suggest verifying the messages you are about to purge by running `$phish |Out-GridView`

4. Run the new Phish search command
    ```powershell
    New-PhishSearchFromMT -MTLogs $phish -Description 'Phish from ryan@badguys.com'
    ```
5. Wait for the search to finish

    Verifying a specific search via PowerShell
    ```powershell
    Get-ComplianceSearch -Name 'Phish from ryan@badguys.com'

    Name                        RunBy  JobEndTime           Status
    ----                        -----  ----------           ------
    Phish from ryan@badguys.com Ryan   8/14/2018 5:47:27 PM Completed
    ```

    Verifying the last search via PowerShell
    ```powershell
    Get-ComplianceSearch |select -last 1

    Name                        RunBy  JobEndTime           Status
    ----                        -----  ----------           ------
    Phish from ryan@badguys.com Ryan   8/14/2018 5:47:27 PM Completed

    ```

    Verify by the [Content Search GUI](https://protection.office.com/?ContentOnly=1#/contentsearchbeta)
6. Purge the results. NOTE THAT PURGING IS DESTRUCTIVE. Use with caution.
