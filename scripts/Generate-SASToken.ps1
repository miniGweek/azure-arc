function Get-StorageAccountSASToken {
    param (
        [Parameter(Mandatory)][String]$AccountName,
        [Parameter(Mandatory)][String]$ContainerName,
        [Parameter(Mandatory)][Datetime]$StartTime,
        [Parameter(Mandatory)][Datetime]$ExpiryTime,
        [Parameter(Mandatory)][String]$Permissions,
        [Switch]$ConvertToBase64
    )
    
    $Protocol = "HttpsOnly"

    # Create a context object using Azure AD credentials, retrieve container
    $Ctx = New-AzStorageContext -StorageAccountName $AccountName  -UseConnectedAccount

    # Generate SAS token for a specific container
    $SASTokenWithoutLeadingQuestionMark = ""
    $SASToken = New-AzStorageContainerSASToken `
        -Context $Ctx `
        -Name $ContainerName `
        -StartTime $StartTime `
        -ExpiryTime $ExpiryTime `
        -Permission $Permissions `
        -Protocol $Protocol

    if ($True -eq ($SASToken -Match "^(\?)(.+)")) {
        $SASTokenWithoutLeadingQuestionMark = $Matches[2];
    }
    else {
        $SASTokenWithoutLeadingQuestionMark = $SASToken
    }
   
    if ($ConvertToBase64.IsPresent) {
        $SASTokenBytes = [System.Text.Encoding]::Unicode.GetBytes($SASTokenWithoutLeadingQuestionMark)
        $SASTokenBase64String = [Convert]::ToBase64String($SASTokenBytes)
        return $SASTokenBase64String
    }
    return  $SASTokenWithoutLeadingQuestionMark
}
