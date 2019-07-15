if ($env:BHBuildSystem -ne 'Unknown' -and $ENV:BHBranchName -eq "master") {
Deploy Module {
        By PSGalleryModule {
            FromSource $env:BHProjectName
            To PowerShell
            WithOptions @{
                ApiKey = $env:NugetApiKey
                Force = $true
            }
        }
    }
}
else {
    "Skipping deployment: To deploy, ensure that...`n" +
    "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
    "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
    "`t* Module path is valid (Current: )" |
        Write-Host
}
