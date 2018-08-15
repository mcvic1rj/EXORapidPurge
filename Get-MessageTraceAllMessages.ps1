function Get-MessageTraceAllMessages {
    [cmdletbinding()]
    param(
        [datetime]$StartDate = ((get-date).adddays(-7)),
        [datetime]$EndDate = (get-date),
        [ipaddress]$FromIP,
        [String]$RecipientAddress,
        [String]$SenderAddress,
        [ValidateSet("None", "Failed", "Pending", "Delivered", "Expanded")]
        $Status,
        [ValidateRange(1, 5000)]
        [Int]$PageSize = 5000
    )
    begin {
        if($IncludeGeoIPData){
            Write-Warning -Message "Including GeoIP Info increases the time this command runs by 5 times."
        }
        $MessageTraceParameters = @{}
        if ($StartDate) {
            $MessageTraceParameters.Add('StartDate', $StartDate)
        }
        if ($EndDate) {
            $MessageTraceParameters.Add('EndDate', $EndDate)
        }
        if ($FromIP) {
            $MessageTraceParameters.Add('FromIP', $FromIP)
        }
        if ($RecipientAddress) {
            $MessageTraceParameters.Add('RecipientAddress', $RecipientAddress)
        }
        if ($SenderAddress) {
            $MessageTraceParameters.Add('SenderAddress', $SenderAddress)
        }
        if ($Status) {
            $MessageTraceParameters.Add('Status', $Status)
        }
        if ($PageSize) {
            $MessageTraceParameters.Add('PageSize', $PageSize)
        }
        Write-Verbose -Message "Calling Get-MessageTrace with $($MessageTraceParameters|Out-String)"
        if (!(Get-Command Get-MessageTrace -ErrorAction SilentlyContinue)) {
            Write-Error -Message "No Office 365 session imported. Please import a valid session first." -ErrorAction stop
        }
        $i = 1 #Inital Counter
        $AllMessages = @()
        $ReturnedMessages = @()
    }
    process {

        #Start pulling messages
        do {
            Write-Verbose -Message ('Entering Do-whileloop Iteration {0}' -f $i)
            $this = Get-MessageTrace -Page $i @MessageTraceParameters
            $AllMessages += $this
            Write-Verbose -Message "Found $($this.count) messages for a total of $($AllMessages.count) on page $i"
            $i++
        }while ($this -ne $null)

        Write-Verbose ('Total of {0} message(s) found' -f $AllMessages.count)

        if ($IncludeGeoIPData) {
            Write-verbose -Message "Including GeoIP Info"
            $UniqueIPs = $AllMessages.FromIP|select -Unique
            Write-Verbose -Message "Found these unique IPs: $($uniqueIPs|out-string)"
            foreach ($UniqueIP in $UniqueIPs) {
                Try{
                    $GeoIPInfo = Get-GeoIPLocation -IPAddress $UniqueIP
                }Catch{
                    $GeoIPInfo=New-Object -TypeName psobject -Property ([ordered]@{
                        IPAddress     = $UniqueIP
                        Country       = $Null
                        CountryCode   = $Null
                        RegionCode    = $Null
                        RegionName    = $Null
                        City          = $Null
                        PostalCode    = $Null
                        TimeZone      = $Null
                        Latitude      = $Null
                        Longitude     = $Null
                        MetroCode     = $Null
                        Continent     = $Null
                        ContinentCode = $Null
                    })
                }
                $TheseMessages = $AllMessages|? {$_.FromIP -eq "$($GeoIPInfo.IPAddress)"}
                Write-Verbose -Message ("Found {0} message(s) with IP address: {1}" -f $TheseMessages.count,$UniqueIP)
                Foreach ($message in $TheseMessages) {
                    $thisMessage = $message
                    $thisMessage|Add-Member NoteProperty City $GeoIPInfo.City -force
                    $thisMessage|Add-Member NoteProperty Continent $GeoIPInfo.Continent -force
                    $thisMessage|Add-Member NoteProperty ContinentCode $GeoIPInfo.ContinentCode -force
                    $thisMessage|Add-Member NoteProperty Country $GeoIPInfo.Country -force
                    $thisMessage|Add-Member NoteProperty CountryCode $GeoIPInfo.CountryCode -force
                    $thisMessage|Add-Member NoteProperty Latitude $GeoIPInfo.Latitude -force
                    $thisMessage|Add-Member NoteProperty Longitude $GeoIPInfo.Longitude -force
                    $thisMessage|Add-Member NoteProperty MetroCode $GeoIPInfo.MetroCode -force
                    $thisMessage|Add-Member NoteProperty PostalCode $GeoIPInfo.PostalCode -force
                    $thisMessage|Add-Member NoteProperty RegionCode $GeoIPInfo.RegionCode -force
                    $thisMessage|Add-Member NoteProperty RegionName $GeoIPInfo.RegionName -force
                    $thisMessage|Add-Member NoteProperty TimeZone $GeoIPInfo.TimeZone -force
                    $ReturnedMessages+=$thisMessage
                    Remove-Variable -Name thisMessage
                }
            }

        }
        else{
            $ReturnedMessages=$AllMessages|select -Property FromIP, MessageId, MessageTraceId, Organization, Received, SenderAddress, RecipientAddress, Size, Status, Subject, ToIP
        }
        Return $ReturnedMessages
    }
}