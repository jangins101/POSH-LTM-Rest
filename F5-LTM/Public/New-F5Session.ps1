Function New-F5Session{
<#
.SYNOPSIS
    Generate an F5 session object to be used in querying and modifying the F5 LTM
.DESCRIPTION
    This function takes the DNS name or IP address of the F5 LTM device, and a PSCredential credential object
    for a user with permissions to work with the REST API. Based on the scope value, it either returns the 
    session object (local scope) or adds the session object to the script scope
#>
    [cmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        [Parameter(Mandatory=$true)][string]$LTMName,
        [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$LTMCredentials,
        [switch]$Default,
        [switch]$PassThrough
    )

    $BaseURL = "https://$LTMName/mgmt/tm/ltm/"
    
    
    $newSession = [pscustomobject]@{Name = $LTMName; BaseURL = $BaseURL; Credential = $LTMCredentials} | Add-Member -Name GetLink -MemberType ScriptMethod {
         param($Link)
         $Link -replace 'localhost', $this.Name    
    } -PassThru 

    #If the Default switch is set, and/or if no script-scoped F5Session exists, then set the script-scoped F5Session
    If ($Default -or !($Script:F5Session)){
        $Script:F5Session = $newSession
    }

    #If the Passthrough switch is set, then return the created F5Session object.
    If ($PassThrough){
        $newSession
    }
}

New-Alias -Name Connect-F5Session -Value New-F5Session;