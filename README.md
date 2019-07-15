# WDSDsc

This repository contains the Windows Deployment Services DSC Resource Module.

## WdsInitialize

Configure a WDS server.
- IsSingleInstance: Key property, there can only be one WDS instance
- Standalone: Indicates that this is a standalone server, not integrated into ADDS
- ComputerName: The remote system to configure. Requires DCOM/RPC and valid credentials (PSDSCRunAsCredential)
- Path: Path to RemInst share on the host
- Authorized: Indicates that the host is authorized in DHCP
