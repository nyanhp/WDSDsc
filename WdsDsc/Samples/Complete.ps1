<#
This configuration enables DHCP Server, creates a scope and a reservation and initalizes WDS
#>
configuration complete
{
    Import-DscResource -ModuleName xDhcpServer -ModuleVersion 2.0.0.0
    Import-DscResource -ModuleName WdsDsc -ModuleVersion 0.11.0

    WindowsFeature dhcp
    {
        Name                 = 'DHCP'
        IncludeAllSubFeature = $true
        Ensure               = 'Present'
    }

    WindowsFeature wds
    {
        Name                 = 'WDS'
        IncludeAllSubFeature = $true
        Ensure               = 'Present'
    }

    WdsInitialize init
    {
        DependsOn        = '[WindowsFeature]dhcp', '[WindowsFeature]wds'
        IsSingleInstance = 'yes'
        Path             = 'C:\RemInst'
        Authorized       = $true
        Ensure           = 'Present'
    }

    xDhcpServerScope clients
    {
        DependsOn    = '[WdsInitialize]init'
        Name         = 'Clients'
        ScopeId      = '192.168.12.0'
        SubnetMask   = '255.255.255.0'
        IPStartRange = '192.168.12.20'
        IPEndRange   = '192.168.12.120'
    }

    xDhcpServerReservation tst
    {
        DependsOn        = '[xDhcpServerScope]clients'
        IPAddress        = '192.168.12.22'
        ClientMACAddress = '00-15-5D-02-28-37'
        Name             = 'tst'
        ScopeID          = '192.168.12.0'
    }

    WdsDeviceReservation dev
    {
        DependsOn       = '[WdsInitialize]init'
        DeviceID        = '00-15-5D-02-28-37'
        DeviceName      = 'tst'
        PxePromptPolicy = 'NoPrompt'
        JoinDomain      = $true
        Domain          = 'contoso.com'
        JoinRights      = 'JoinOnly'
        Ensure          = 'Present'
    }

    WdsBootImage booty
    {
        DependsOn    = '[WdsInitialize]init'
        Path         = 'D:\sources\boot.wim'
        NewImageName = 'contoso boot'
    }

    WdsInstallImage instally
    {
        DependsOn    = '[WdsInitialize]init'
        Path         = 'D:\sources\install.wim'
        ImageName    = 'Windows Server SERVERDATACENTERACORE'
        NewImageName = 'Contoso custom Windows'
    }
}

complete