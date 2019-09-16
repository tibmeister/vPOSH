![GitHub issues](https://img.shields.io/github/issues-raw/tibmeister/vPOSH?style=plastic) ![GitHub](https://img.shields.io/github/license/tibmeister/vPOSH?style=plastic)

# vPOSH

PowerShell based framework for VMware vSphere. As a framework, there will be a number of external modules that will be part of this framework, but the core of the framework is in this repository.

# Prerequisites

Powershell v5 or higher must be installed along with PowerCLI 10.2.0.9372002 or higher.

# Installing / Getting Started

a **vcenters.json** file must be present in the _.config_ folder in order to allow for a Connect-vCenter cmdlet to function correctly. the format of this file is as follows:

```
[
    {
        "vCenter": "vCenterFQDN",
        "AutoConnect": true,
        "Environment": "Production",
        "Location": "Datacenter1"
    }
]
```

For **AutoConnect**, this is a true/false value and will be used to determine if the **AutoConnect** feature of the cmdlet is used.

# Versioning

Based on Semantec Versioning, the following will be used:
*Major Version.Minor Version.Patch*

Any new module will trigger a Minor version change, as will any new feature being added. Removing a feature or any other major changes that could break any existing code will trigger a Major version change. General commits to fix issues or enhance existing features will trigger a Patch increment.

# Release History
