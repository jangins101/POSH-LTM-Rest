Function Get-NodeAssociations {
<#
.SYNOPSIS
    Grab references to nodeÿ[s] (virtuals, iRules, pools)
.NOTES
    Node names are case-specific.
#>
    [cmdletBinding()]
    param (
        [Alias('NodeName')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]$Partition,
                
        $F5Session=$Script:F5Session
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)

        Write-Verbose "NB: Node names are case-specific."
    }
    process {
        # Return object
        $associations = [PSCustomObject]@{
            Virtuals = @();
            Pools = @();
            Rules = @();
        };

        # Grab all the lookups
        $vips = Get-VirtualServer -F5Session $F5Session;
        $pools = Get-Pool -F5Session $F5Session;
        $rules = Get-iRule -F5Session $F5Session;
        
        # Grab the nodes list
        $nodes = ($Name | Get-Node -F5Session $F5Session);

        foreach ($node in $nodes) {
            # Get associated pools
            $assocPools = ($node | Get-PoolsForMember -F5Session $F5Session);
            $associations.Pools += $assocPools;

            # Filter the associated virtuals
            $assocPoolPaths = $assocPools | Select-Object -ExpandProperty fullPath;
            $associations.Virtuals  += ($vips | ?{ $assocPoolPaths -contains $_.pool });
            
            # Get the associated iRules
            $filter = "\W+(?:node\W*(?:$($node.name)|$($node.fullPath)))|(?:pool\W*(?:$([string]::Join('|', $($assocPools | Select-Object -ExpandProperty name)))))|(?:pool\W*(?:$([string]::Join('|', $($assocPools | Select-Object -ExpandProperty fullPath)))))\W+";
            $associations.Rules += $rules | ?{ $_.apiAnonymous -match $filter };
        }
                
        # Return the associations
        $associations;
    }
}