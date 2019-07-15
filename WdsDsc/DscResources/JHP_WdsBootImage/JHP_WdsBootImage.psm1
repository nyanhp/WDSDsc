function Get-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $NewImageName,

        [string]
        $NewDescription,

        [uint32]
        $DisplayOrder,

        [bool]
        $SkipVerify,
        
        [string]
        $NewFileName,
        
        [string]
        $TransmissionName,

        [bool]
        $Multicast,
        
        [string]
        $Path,

        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present',

        [ValidateSet("X86", "Ia64", "X64", "Arm")]
        [string]
        $Architecture
    )

    $bootImageParam = if (-not [string]::IsNullOrWhiteSpace($NewImageName))
    {
        @{
            ImageName   = $NewImageName
            ErrorAction = 'SilentlyContinue'
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($NewFileName))
    {
        @{
            FileName    = $NewFileName
            ErrorAction = 'SilentlyContinue'
        }
    }
    else
    {
        @{
            FileName    = Split-Path -Path $Path -Leaf
            ErrorAction = 'SilentlyContinue'
        }
    }

    $bootImage = Get-WdsBootImage @bootImageParam

    if ($null -eq $bootImage)
    {
        $imgName = (Get-WindowsImage -ImagePath $Path -Index 2 -ErrorAction SilentlyContinue).ImageName
        $bootImage = Get-WdsBootImage -ImageName $imgName -ErrorAction SilentlyContinue
    }

    return @{
        NewImageName     = $bootImage.ImageName
        NewDescription   = $bootImage.Description
        NewFileName      = $bootImage.FileName
        DisplayOrder     = $bootImage.DisplayOrder
        SkipVerify       = $SkipVerify
        TransmissionName = $TransmissionName
        Multicast        = $Multicast
        Path             = $Path
        Ensure           = $Ensure
        Architecture     = $bootImage.Architecture
    }
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $NewImageName,

        [string]
        $NewDescription,

        [uint32]
        $DisplayOrder,

        [bool]
        $SkipVerify,
        
        [string]
        $NewFileName,
        
        [string]
        $TransmissionName,

        [bool]
        $Multicast,
        
        [string]
        $Path,

        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present',

        [ValidateSet("X86", "Ia64", "X64", "Arm")]
        [string]
        $Architecture
    )
    
    $parameters = [hashtable] $PSBoundParameters
    $parameters.Remove('Ensure')

    if ([string]::IsNullOrWhiteSpace($NewImageName))
    {
        $NewImageName = (Get-WindowsImage -ImagePath $Path -Index 2 -ErrorAction SilentlyContinue).ImageName
    }

    if ($Ensure -eq 'Absent')
    {
        if ([string]::IsNullOrWhiteSpace('Architecture'))
        {
            throw "When Ensure is set to Absent, the Architecture may not be empty."
        }

        Write-Verbose -Message "Removing $NewImageName ($Architecture)"
        $null = Remove-WdsBootImage -Architecture $Architecture -ImageName $NewImageName -ErrorAction Stop
        return
    }

    if ([string]::IsNullOrWhiteSpace((Get-TargetResource @PSBoundParameters).NewImageName))
    {
        Write-Verbose -Message "Importing $NewImageName ($Architecture)"
        $null = Import-WdsBootImage @parameters
        return
    }

    $parameters.Remove('NewImageName')
    $parameters.Remove('Path')

    if (-not $Multicast)
    {
        $parameters['StopMulticastTransmission'] = $true
    }
    
    Write-Verbose -Message "Updating $NewImageName ($Architecture)"
    $null = Set-WdsBootImage -ImageName $NewImageName @parameters
}

function Test-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $NewImageName,

        [string]
        $NewDescription,

        [uint32]
        $DisplayOrder,

        [bool]
        $SkipVerify,
        
        [string]
        $NewFileName,
        
        [string]
        $TransmissionName,

        [bool]
        $Multicast,
        
        [string]
        $Path,

        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present',

        [ValidateSet("X86", "Ia64", "X64", "Arm")]
        [string]
        $Architecture
    )

    $currentStatus = Get-TargetResource @PSBoundParameters
    $parameters = [hashtable] $PSBoundParameters
    foreach ($parameter in @('Verbose', 'Debug', 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'OutVariable'))
    {
        $parameters.Remove($parameter)
    }
    
    if ($Ensure -eq 'Absent')
    {
        return [string]::IsNullOrWhiteSpace($currentStatus.NewImageName)
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