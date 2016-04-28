Function Get-PoolAssociations {
<#
.SYNOPSIS
    Grab references to pool[s] (virtuals, iRules, nodes)
.NOTES
    Pool names are case-specific.
#>
    [cmdletBinding()]
    param (
        [Alias('PoolName')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,
                
        $F5Session=$Script:F5Session
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Pool names are case-specific."
    }
    process {
        # Return object
        $associations = [PSCustomObject]@{
            Virtuals = @();
            Nodes = @();
            Rules = @();
        };

        # Grab all the lookups
        $vips = Get-VirtualServer -F5Session $F5Session;
        $rules = Get-iRule -F5Session $F5Session;

        foreach ($poolName in $name) {
            $pool = Get-Pool -F5Session $F5Session -Name $poolName;
            
            # Filter the associated virtuals 
            $associations.Virtuals  += ($vips | ?{ $_.pool -eq $pool.fullPath });
            
            # Get the associated nodes
            $poolMembers = @($pool | Get-PoolMember -F5Session $F5Session);
            $associations.Nodes += ($poolMembers | %{ Get-Node -F5Session $f5session -Address $_.address });
            
            # Get the associated iRules
            $associations.Rules += $rules | ?{ $_.apiAnonymous -like "*pool $($pool.name)*" -or $_.apiAnonymous -like "*pool $($pool.fullPath)*" };
        }
                
        # Return the associations
        $associations;
    }
}