function New-PhishSearchFromMT {
    param(
        # Subject of the Message
        [Parameter(Mandatory=$true)]
        $MTLogs,
        [string]$Description

    )

    begin{
        $Senders=$MTLogs.senderaddress|select -Unique
        $Subjects=$MTLogs.Subject|select -Unique
        $ReceivedDate=$MTLogs.received|Sort|select -First 1
        $RecipientList=$MTLogs.recipientaddress|select -unique
        $CMQ='(c:c)'
        foreach ($sender in $senders){
            $CMQ+='(from:"{0}")' -f $sender
        }
        foreach ($Subject in $Subjects){
            $CMQ+='(subject:"{0}")' -f $Subject
        }
        $CMQ+='(received>{0})' -f (Get-Date -Format yyyy-MM-dd -Date ($ReceivedDate).AddDays(-2))
    }
    process{
        Write-Host "New-ComplianceSearch -ExchangeLocation `$RecipientList -Name $SenderADdress -ContentMatchQuery '$CMQ'"
        New-ComplianceSearch -ExchangeLocation $RecipientList -Description $Description -ContentMatchQuery $CMQ -Name $Description
        start-compliancesearch -identity $Description
    }
    end{

    }
}