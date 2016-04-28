Function Rename-Node {
<#
.SYNOPSIS
    Attempts to rename a node.

.DESCRIPTION
    Expects $NodeAddress to be an IPAddress object. 
    $NodeName is optional, and will default to the IPAddress is not included
    Returns the new node definition

.EXAMPLE
    Rename-Node -F5Session $F5Session -Name "MyNodeName" -Address 10.0.0.1 -Description "My node description"

#>   
    [cmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true)]
        [Alias("Name")]
        [String]$NodeName,

        [Parameter(Mandatory=$false)]
        [Alias("NewName")]
        [String]$NodeNewName,
        
        [Parameter(Mandatory=$false)]
        [String]$Partition,
        
        $F5Session=$Script:F5Session
    )
    begin {
        #Test that the F5 session is in a valid format
        Test-F5Session($F5Session)
    }
    process {
        Write-Verbose "Rename node from '$NodeName' to '$NodeNewName'";

        # Get the original node
        $node = Get-Node -F5Session $F5Session -Name $NodeName;
        Write-Verbose "  Node retrieved - $($node | ConvertTo-Json -Compress)";

        # Make sure the node exists
        if ($node) {
            # Get the pools associated with this node
            $pools = Get-PoolsForMember -F5Session $F5Session -Address $node.address;
            Write-Verbose "  Retrieved pools for node ($($pools.Length) found)";

            # Get the individual pool members that we'll remove and re-add (keeping the current config)
            $members = $pools | %{
                $mem = Get-PoolMember -F5Session $F5Session -InputObject $_ -Address $node.address;
                [PSCustomObject]@{ Pool=$_; Members=$mem; }; 
            }

            # Remove the pool members using this node
            $pools | Remove-PoolMember -F5Session $F5Session -Address $node.address -ErrorAction Stop -Confirm:$false;
            Write-Verbose "  Pool members removed";

            # Attempt to delete the node (errors if in use)
            $node | Remove-Node -F5Session $F5Session;
            Write-Verbose "  Node removed";

            # Create the new node
            $node.name = $NodeNewName;                                                # We want to add the new object the way it was before
            if ($node.session -like 'monitor-*') { $node.session = 'user-enabled' }   # Create fails if we try to set the session to monitor-disabled or monitor-enabled
            $properties = $node | Select-Object * -ExcludeProperty @("selfLink", "kind", "generation", "state")
            $newNode = New-Node -Properties $properties -PassThrough
            Write-Verbose "  Node added - $($newNode | ConvertTo-Json -Compress)";

            # Add the pool members back
            foreach ($mem in $members) {
                foreach ($memMember in $mem.Members) {
                    $memMember.name = $memProps.name -replace @($NodeName, $NodeNewName);
                    $memMember.fullPath = $memProps.fullPath -replace @($NodeName, $NodeNewName);
                    if ($memMember.session -like 'monitor-*') { $memMember.session = 'user-enabled' }   # Create fails if we try to set the session to monitor-disabled or monitor-enabled
                    $memProps = $memMember | Select-Object * -ExcludeProperty @("kind", "selfLink", "fullPath", "generation", "address", "state");
                    [void]($mem.Pool | Add-PoolMember -F5Session $F5Session -MemberProperties $memProps);
                }
            }
        }
    }
}