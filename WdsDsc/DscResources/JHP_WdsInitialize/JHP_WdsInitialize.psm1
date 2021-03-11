function Start-NetProcess
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter()]
        [string[]]
        $ArgumentList,
        $ExpectedReturnCodes = @(0, 3010)
    )

    $process = New-Object -TypeName System.Diagnostics.Process
    $si = New-Object -TypeName System.Diagnostics.ProcessStartInfo
    $si.FileName = $Path

    if ($null -ne $ArgumentList)
    {
        $si.Arguments = $ArgumentList
    }
    
    $si.RedirectStandardOutput = $true
    $si.RedirectStandardError = $true
    $si.UseShellExecute = $false
    $process.StartInfo = $si
    $null = $process.Start()
    $out = $process.StandardOutput.ReadToEnd()
    $err = $process.StandardError.ReadToEnd()
    $null = $process.WaitForExit()

    if ($process.ExitCode -notin $ExpectedReturnCodes)
    {
        throw "$process exited with $($process.ExitCode), output: $out, error stream $err"
    }

    [PSCustomObject]@{
        Output   = $out
        Error    = $err
        ExitCode = $process.ExitCode
    }
}

function Get-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('Yes')]
        [string]
        $IsSingleInstance,

        [Parameter(Mandatory)]
        [String]
        $Path,

        [Parameter()]
        [String]
        $ComputerName,

        [Parameter()]
        [Boolean]
        $Standalone,

        [Parameter()]
        [Boolean]
        $Authorized,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    $wdscmd = Get-Command -Name wdsutil -CommandType Application -ErrorAction Stop

    $wdsutilArguments = @(
        if ($PSBoundParameters.ContainsKey('ComputerName')) { "/Server:$ComputerName" } else { $ComputerName = $env:COMPUTERNAME }
        '/Get-Server'
        '/Show:Config'
    )

    $data = Start-NetProcess -Path $wdscmd.Source -ArgumentList $wdsutilArguments -ErrorAction SilentlyContinue
    
    $null = $data.Output -match 'RemoteInstall location:\s*(?<Path>[\w:\\]+)'
    $remPath = $Matches.Path

    return @{
        IsSingleInstance = $IsSingleInstance
        Path             = $remPath
        ComputerName     = $ComputerName
        Standalone       = $data.Output -match 'Standalone configuration:\s*yes'
        Authorized       = $Authorized
        Configured       = $data.Output -notmatch 'WDS operational mode: Not Configured'
    }
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('Yes')]
        [string]
        $IsSingleInstance,

        [Parameter(Mandatory)]
        [String]
        $Path,

        [Parameter()]
        [String]
        $ComputerName,

        [Parameter()]
        [Boolean]
        $Standalone,

        [Parameter()]
        [Boolean]
        $Authorized,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    $wdscmd = Get-Command -Name wdsutil -CommandType Application -ErrorAction Stop

    $wdsutilArguments = @(
        if ($PSBoundParameters.ContainsKey('ComputerName')) { "/Server:$ComputerName" } else { $ComputerName = $env:COMPUTERNAME }
        if ($Ensure -eq 'Present')
        {
            '/Initialize-Server'
            '/REMINST:"{0}"' -f $Path
            if ($Authorized) { '/Authorize' }
            if ($Standalone) { '/Standalone' }
        } 
        else 
        { 
            '/Uninitialize-Server'
        }
    )

    $result = Start-NetProcess -Path $wdscmd.Source -ArgumentList $wdsutilArguments -ErrorAction SilentlyContinue

    if ($result.ExitCode -eq 0)
    {
        1..3 | ForEach-Object { Start-Service -Name WdsServer -ErrorAction SilentlyContinue }
        Set-Service -Name WdsServer -StartupType Automatic
    }
}
function Test-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('Yes')]
        [string]
        $IsSingleInstance,

        [Parameter(Mandatory)]
        [String]
        $Path,

        [Parameter()]
        [String]
        $ComputerName,

        [Parameter()]
        [Boolean]
        $Standalone,

        [Parameter()]
        [Boolean]
        $Authorized,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    $current = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq 'Present')
    {
        return ($Path -eq $current.Path -and $Standalone -eq $current.Standalone)
    }

    return (-not $current.Configured)
}
