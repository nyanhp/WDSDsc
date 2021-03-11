﻿function Get-TargetResource
{
    param
    (
        [bool]
        $SkipVerify,

        [string]
        $ImageGroup,

        [uint32]
        $DisplayOrder,

        [string]
        $UnattendFile,

        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $NewImageName,

        [string]
        $NewDescription,

        [string]
        $NewFileName,

        [Parameter(Mandatory)]
        [string]
        $ImageName,

        [uint32]
        $ClientCount,
        
        [datetime]
        $StartTime,

        [string]
        $TransmissionName,

        [bool]
        $Multicast,

        [bool]
        $ManualStart,

        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present'
    )

    $currentImage = Get-WdsInstallImage -ImageName $NewImageName -ErrorAction SilentlyContinue

    return @{
        SkipVerify       = $SkipVerify
        ImageGroup       = $currentImage.ImageGroup
        DisplayOrder     = $currentImage.DisplayOrder
        UnattendFile     = $UnattendFile
        Path             = $Path
        NewImageName     = $currentImage.ImageName
        NewDescription   = $currentImage.Description
        NewFileName      = $currentImage.FileName
        ImageName        = $ImageName
        ClientCount      = $ClientCount
        StartTime        = $StartTime
        TransmissionName = $TransmissionName
        Multicast        = $Multicast
        ManualStart      = $ManualStart
    }
}

function Set-TargetResource
{
    param
    (
        [bool]
        $SkipVerify,

        [string]
        $ImageGroup,

        [uint32]
        $DisplayOrder,

        [string]
        $UnattendFile,

        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $NewImageName,

        [string]
        $NewDescription,

        [string]
        $NewFileName,

        [Parameter(Mandatory)]
        [string]
        $ImageName,

        [uint32]
        $ClientCount,
        
        [datetime]
        $StartTime,

        [string]
        $TransmissionName,

        [bool]
        $Multicast,

        [bool]
        $ManualStart,

        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present'
    )

    $currentStatus = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq 'Absent')
    {
        $null = Remove-WdsInstallImage -ImageName $NewImageName
        return
    }

    $parameters = [hashtable] $PSBoundParameters
    $Parameters.Remove('Ensure')

    $TempUnattendFile = New-TemporaryFile
    
    try 
    {
        # the unattend file will be copied with all file attributes -> so we make a temporary copy to make it writeable for WDS
        # if a readonly unattend file is copied, an installation of a computer based on this image will not use the unattend file
        if( -not [string]::IsNullOrWhiteSpace($UnattendFile) -and (Test-Path -Path $UnattendFile) )
        {
            try 
            {
                Copy-Item -Path $UnattendFile -Destination $TempUnattendFile -ErrorAction Stop
                $TempUnattendFile.Attributes = 'Normal'
                $parameters.UnattendFile = $TempUnattendFile.FullName
            }
            catch
            {
                # try the original parameter
            }
        }

        if ($Ensure -eq 'Present' -and -not [string]::IsNullOrWhiteSpace($currentStatus.NewImageName))
        {
            $parameters.Remove('Path')
            $parameters.ImageName = $Parameters.NewImageName
            $parameters.Remove('NewImageName')
            $null = Set-WdsInstallImage @parameters
            return
        }
    
        $null = Import-WdsInstallImage @parameters
    }
    finally
    {
        # remove temporary file
        Remove-Item -Path $TempUnattendFile -ErrorAction SilentlyContinue
    }
}

function Test-TargetResource
{
    param
    (
        [bool]
        $SkipVerify,

        [string]
        $ImageGroup,

        [uint32]
        $DisplayOrder,

        [string]
        $UnattendFile,

        [string]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $NewImageName,

        [string]
        $NewDescription,

        [string]
        $NewFileName,

        [Parameter(Mandatory)]
        [string]
        $ImageName,

        [uint32]
        $ClientCount,
        
        [datetime]
        $StartTime,

        [string]
        $TransmissionName,

        [bool]
        $Multicast,

        [bool]
        $ManualStart,

        [ValidateSet("Present", "Absent")]
        [string]
        $Ensure = 'Present'
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
