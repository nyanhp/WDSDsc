
function Get-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $DeviceID,

        [Parameter(Mandatory)]
        [string]
        $DeviceName,

        [string]
        $User,

        [ValidateSet("Abort", "NoPrompt", "OptIn", "OptOut")]
        [string]
        $PxePromptPolicy,

        [ValidateSet("Full", "JoinOnly")]
        [string]
        $JoinRights,

        [string]
        $Group,

        [string]
        $WdsClientUnattend,

        [string]
        $BootImagePath,

        [string]
        $OU,

        [string]
        $Domain,

        [string]
        $ReferralServer,

        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present',

        [boolean]
        $JoinDomain
    )

    $device = Get-WdsClient -DeviceName $DeviceName -ErrorAction SilentlyContinue

    return @{
        BootImagePath     = $device.BootImagePath
        DeviceID          = $device.DeviceID
        DeviceName        = $device.DeviceName
        Domain            = $device.Domain
        Group             = $device.Group
        JoinDomain        = $device.JoinDomain
        JoinRights        = $device.JoinRights
        PxePromptPolicy   = $device.PxePromptPolicy
        ReferralServer    = $device.ReferralServer
        User              = $device.User
        WdsClientUnattend = $device.WdsClientUnattend
        Ensure            = $Ensure
    }
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $DeviceID,

        [Parameter(Mandatory)]
        [string]
        $DeviceName,

        [string]
        $User,

        [ValidateSet("Abort", "NoPrompt", "OptIn", "OptOut")]
        [string]
        $PxePromptPolicy,

        [ValidateSet("Full", "JoinOnly")]
        [string]
        $JoinRights,

        [string]
        $Group,

        [string]
        $WdsClientUnattend,

        [string]
        $BootImagePath,

        [string]
        $OU,

        [string]
        $Domain,

        [string]
        $ReferralServer,

        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present',

        [boolean]
        $JoinDomain
    )

    $currentConfig = Get-TargetResource @PSBoundParameters
    $parameters = [hashtable]$PSBoundParameters
    $parameters.Remove('Ensure')

    if( -not [string]::IsNullOrWhiteSpace( $JoinRights ) -and [string]::IsNullOrWhiteSpace( $User ) )
    {
        throw "ERROR: Parameter 'JoinRights' requires an none empty parameter 'User'." 
    } 

    if( -not [string]::IsNullOrWhiteSpace( $User ) -and [string]::IsNullOrWhiteSpace( $JoinRights ) )
    {
        throw "ERROR: Parameter 'User' requires an none empty parameter 'JoinRights'."
    }

    if ($null -ne $currentConfig.DeviceName -and $Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Removing client '$($currentConfig.DeviceName)'"
        Remove-WdsClient -DeviceName $currentConfig.DeviceName
    }
    elseif ($null -ne $currentConfig.DeviceName)
    {
        # Domain is a now switch parameter and must be set to true. Domain name is moved to parameter DomainName
        if( -not [string]::IsNullOrWhiteSpace( $Domain ) )
        {
            $parameters.DomainName = $Domain
            $parameters.Domain = $true
        }
        else
        {
            $parameters.Remove('Domain')
        }

        # paramter OU can't be set
        $parameters.Remove( 'OU' )

        Write-Verbose -Message "Updating client '$DeviceName'"
        Set-WdsClient @parameters
    }
    else
    {
        Write-Verbose -Message "Creating new client '$DeviceName' with ID '$DeviceID'"
        New-WdsClient @parameters
    }
}

function Test-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $DeviceID,

        [Parameter(Mandatory)]
        [string]
        $DeviceName,

        [string]
        $User,

        [ValidateSet("Abort", "NoPrompt", "OptIn", "OptOut")]
        [string]
        $PxePromptPolicy,

        [ValidateSet("Full", "JoinOnly")]
        [string]
        $JoinRights,

        [string]
        $Group,

        [string]
        $WdsClientUnattend,

        [string]
        $BootImagePath,

        [string]
        $OU,

        [string]
        $Domain,

        [string]
        $ReferralServer,

        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present',

        [boolean]
        $JoinDomain
    )

    $currentStatus = Get-TargetResource @PSBoundParameters
    $parameters = [hashtable]$PSBoundParameters
    # filter attributes that cannot be set again
    foreach ($parameter in @('OU', 'User', 'Verbose', 'Debug', 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'OutVariable'))
    {
        $parameters.Remove($parameter)
    }

    if ($Ensure -eq 'Absent')
    {
        return ($null -eq $currentStatus.DeviceName)
    }

    foreach ($kvp in $parameters.GetEnumerator())
    {
        Write-Verbose -Message "Parameter value of parameter $($kvp.Key) is $($kvp.Value), currently configured value is $($currentStatus[$kvp.Key])"

        if ($currentStatus[$kvp.Key] -ne $kvp.Value)
        {
            Write-Verbose -Message 'Values do not match.'
            return $false
        }
    }

    return $true
}
