
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

        [bool]
        $JoinDomain
    )

    $device = Get-WdsClient -DeviceId $DeviceId -ErrorAction SilentlyContinue

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

        [bool]
        $JoinDomain
    )

    $currentConfig = Get-TargetResource @PSBoundParameters
    $parameters = [hashtable]$PSBoundParameters
    $parameters.Remove('Ensure')

    if ($null -ne $currentConfig.DeviceID -and $Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Removing client ID $($DeviceID)"
        Remove-WdsClient -DeviceId $DeviceID
    }
    elseif ($null -ne $currentConfig.DeviceID)
    {
        Write-Verbose -Message "Updating client ID $($DeviceID)"
        Set-WdsClient @parameters
    }
    else
    {
        Write-Verbose -Message "Creating new client ID $($DeviceID)"
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

        [bool]
        $JoinDomain
    )

    $currentStatus = Get-TargetResource @PSBoundParameters
    $parameters = [hashtable]$PSBoundParameters
    foreach ($parameter in @('Verbose', 'Debug', 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'OutVariable'))
    {
        $parameters.Remove($parameter)
    }

    if ($Ensure -eq 'Absent')
    {
        return ($null -eq $currentStatus.DeviceID)
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