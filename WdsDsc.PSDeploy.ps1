if ($env:BHBuildSystem -ne 'Unknown' -and $ENV:BHBranchName -eq "master")
{
    Deploy Module {
        By PSGalleryModule {
            FromSource (Join-Path $ENV:BHProjectPath $ENV:BHProjectName)
            To PowerShell
            WithOptions @{
                ApiKey = $env:NugetApiKey
                Force  = $true
            }
        }
    }
}
else
{
    "Skipping deployment: To deploy, ensure that...`n" +
    "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
    "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
    "`t* Module path is valid (Current: $(Join-Path $ENV:BHProjectPath $ENV:BHProjectName))" |
    Write-Host
}

if ((Join-Path $ENV:BHProjectPath $ENV:BHProjectName) -and $env:BHBuildSystem -eq 'AppVeyor')
{
    Deploy DeveloperBuild {
        By AppVeyorModule {
            FromSource (Join-Path $ENV:BHProjectPath $ENV:BHProjectName)
            To AppVeyor
            WithOptions @{
                Version = $env:APPVEYOR_BUILD_VERSION
            }
        }
    }
}
