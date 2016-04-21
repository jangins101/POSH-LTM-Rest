Function Get-VirtualAssociations {
<#
.SYNOPSIS
    Grab references to pool[s] (pools, iRules, nodes)
.NOTES
    Virtual names are case-specific.
#>
    [cmdletBinding()]
    param (
        [Alias('VirtualName')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,
                
        $F5Session=$Script:F5Session
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Virtual names are case-specific."
    }
    process {
        # Return object
        $associations = [PSCustomObject]@{
            Nodes = @();
            Pools = @();
            Rules = @();
        };

        # Grab all the lookups
        $pools = Get-Pool -F5Session $F5Session;
        $rules = Get-iRule -F5Session $F5Session;
        
        # Grab the virtuals list
        $virtuals = ($Name | Get-VirtualServer -F5Session $F5Session);

        foreach ($virtual in $virtuals) {
            # Get associated pool
            $associations.Pools += ($virtual.pool | Get-Pool -F5Session $F5Session);;
                        
            # Get associated nodes
            $associations.Nodes += $virtual.pool | Get-PoolMember | Select-Object -ExpandProperty Address | %{ Get-Node -F5Session $f5session -Address $_ }
                        
            # Get the associated iRules
            $associations.Rules += $rules | ?{ $_.apiAnonymous -match "\W+virtual\W+$($virtual.name)|$($virtual.fullPath)\W+" };
        }
                
        # Return the associations
        $associations;
    }
}