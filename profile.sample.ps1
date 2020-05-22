$MaximumHistoryCount = 4096

#Bootstrap Code
$myDocsPath = [environment]::GetFolderPath("mydocuments")
$vPOSHPath = "$($myDocsPath)\vPOSH"
$vPOSHPathTest = "$($myDocsPath)\vPOSHTest"
$global:historyPath = "$($myDocsPath)\WindowsPowerShell\history.clixml"
$env:PSModulePath += ";$($vPOSHPath)\Modules"
$ReposPath = "$($env:HOME)\source\repos"
$Global:vPOSHConfigPath = "$($myDocsPath)\vPOSH_Config\.config"

. "$($vPOSHPath)\gitutils.ps1"

$temp=Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false -WebOperationTimeoutSeconds -1 -DefaultVIServerMode Multiple -InvalidCertificateAction Ignore
#End of Bootstrap Code

#region Setup Window Colors
if($PGSE)
{
        $PGSE.Configuration.Colors.Console.BackgroundColor = 'black'
        $PGSE.Configuration.Colors.Console.ForegroundColor = 'white'
        $PGSE.Configuration.Colors.Console.ErrorBackgroundColor = 'black'
        $PGSE.Configuration.Colors.Console.ErrorForegroundColor = 'red'
        $PGSE.Configuration.Colors.Console.DebugBackgroundColor = 'black'
        $PGSE.Configuration.Colors.Console.DebugForegroundColor = 'yellow'
        $PGSE.Configuration.Colors.Console.WarningBackgroundColor = 'black'
        $PGSE.Configuration.Colors.Console.WarningForegroundColor = 'yellow'
        $PGSE.Configuration.Colors.Console.VerboseBackgroundColor = 'black'
        $PGSE.Configuration.Colors.Console.VerboseForegroundColor = 'cyan'
}
#endregion

# Modify the prompt function to change the console prompt.
# Save the previous function, to allow restoring it back.
$originalPromptFunction = $function:prompt
function global:prompt
{
    # Set Window Title
    $host.UI.RawUI.WindowTitle = "Administrator:$(get-IsAdmin) :: $ENV:USERNAME@$ENV:COMPUTERNAME - $(Get-Location)"

    # Set Prompt
    #Set the top line for current date/time and the last command execution time
    Write-Host ""
    Write-Host (Get-Date -Format G) -NoNewline -ForegroundColor White
    Write-Host " :: " -NoNewline -ForegroundColor DarkGray
    Write-Host "Last Command Execution Time $(get-LastCommandTime)" -ForegroundColor Yellow
    #Set the location starting on a new line
    Write-Host "$(get-ManagedLocation)" -ForegroundColor Green -NoNewline

    #After the location check if it's a Git repository and if so, display the checkedout branch and current statistics
    if(isCurrentDirectoryGitRepository)
    {
        $status = gitStatus
        $currentBranch = $status.branch

        Write-Host(' [') -nonewline -foregroundcolor Yellow
        if ($status.ahead -eq $FALSE)
        {
            # We are not ahead of origin
            Write-Host($currentBranch) -nonewline -foregroundcolor Cyan
        }
        else
        {
            # We are ahead of origin
            Write-Host($currentBranch) -nonewline -foregroundcolor Red
        }

        Write-Host(' +' + $status.added) -nonewline -foregroundcolor Yellow
        Write-Host(' ~' + $status.modified) -nonewline -foregroundcolor Yellow
        Write-Host(' -' + $status.deleted) -nonewline -foregroundcolor Yellow

        if ($status.untracked -ne $FALSE) {
            Write-Host(' !') -nonewline -foregroundcolor Yellow
        }

        Write-Host(']') -nonewline -foregroundcolor Yellow
    }

    Write-Host ">" -ForegroundColor Green -NoNewline

    return " "
 }

function get-ManagedLocation
{
        #MAke the prompt similar to BASH
        if($((Get-Location) -split("\\")).count -gt 3)
        {
                return "[..]\$($(Get-Location).Path.Split("\") | select -Last 1)"
        }
        else
        {
                return $(Get-Location)
        }
}

function global:get-IsAdmin
{
        # Check for Administrator elevation
        $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
        $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
        $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
        $IsAdmin=$prp.IsInRole($adm)

        if ($IsAdmin)
        {
                return $true
        }
        else
        {
                return $false
        }
}

function global:get-LastCommandTime
{
        $lastCommand = Get-History -Count 1
        $lastCommandExecutionTime = $lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime

        if($lastCommandExecutionTime.Days -le 0)
        {
                if($lastCommandExecutionTime.Hours -le 0)
                {
                        if($lastCommandExecutionTime.Minutes -le 0)
                        {
                                if($lastCommandExecutionTime.Seconds -le 0)
                                {
                                        return "$([Math]::Round($lastCommandExecutionTime.TotalMilliseconds, 2)) Milliseconds"
                                }
                                else
                                {
                                        return "$([Math]::Round($lastCommandExecutionTime.TotalSeconds, 2)) Seconds"
                                }
                        }
                        else
                        {
                                return "$([Math]::Round($lastCommandExecutionTime.TotalMinutes, 2)) Minutes"
                        }
                }
                else
                {
                        return "$([Math]::Round($lastCommandExecutionTime.TotalHours, 2)) Hours"
                }
        }
        else
        {
                return "$([Math]::Round($lastCommandExecutionTime.TotalDays, 2)) Days"
        }
}

#region History Handling Functions
function global:import-History
{
        if ((Test-Path $historyPath))
        {
                Clear-History
                Import-Clixml $historyPath | ? {$count++;$true} | Add-History
                Write-Host -Fore Green "`nLoaded $count history item(s).`n"
        }
}

Register-EngineEvent -SourceIdentifier powershell.exiting -SupportEvent -Action { Get-History -Count $MaximumHistoryCount | Export-Clixml $historyPath }
#endregion

#region Load Modules
# if(!(get-host).Name -eq "ConsoleHost")
# {
#     Get-Module -ListAvailable | Where Name -notlike "ISE*" | Import-Module -ErrorAction SilentlyContinue
# }
# else
# {
#     Get-Module -ListAvailable | Import-Module -ErrorAction SilentlyContinue
# }
#endregion

#region Get Crypto Creds
Import-Module Crypto
Import-Module CommonCode
$vCenterCredentials = new-object System.Management.Automation.PSCredential ("domain\myUserID",$(Get-StoredPassword -KeyFile "$($myDocsPath)\private.key" -PasswordFile "$($myDocsPath)\pass"))
$mySqlCreds = new-object System.Management.Automation.PSCredential ("myUserID",$(Get-StoredPassword -KeyFile "$($myDocsPath)\private.key" -PasswordFile "$($myDocsPath)\pass"))
$UcsCreds = new-object System.Management.Automation.PSCredential ("ucs-domain\myUserID",$(Get-StoredPassword -KeyFile "$($myDocsPath)\private.key" -PasswordFile "$($myDocsPath)\pass"))
$global:vCenterCredentials = $vCenterCredentials
#endregion

#region Map the drives
New-PSDrive -Name "Scripts" -PSProvider FileSystem -Root $vPOSHPath -Confirm:$false -ErrorAction SilentlyContinue | out-null
New-PSDrive -Name "Scripts-Test" -PSProvider FileSystem -Root $vPOSHPathTest -Confirm:$false -ErrorAction SilentlyContinue | out-null
Push-Location Scripts:
#endregion

#region Custom Aliases and Quick Functions
New-Alias -Name i -Value Invoke-History -Description "Invoke history alias"

Rename-Item Alias:\h original_h -Force

#BASH style history
function history($arg) { Get-History -c $MaximumHistoryCount | out-string -stream | select-string $arg }

function EasyView { process { $_; Start-Sleep -seconds 1}}

New-Alias -Name scrollmore -Value EasyView -Description "More function with 1 second autoscroll"
#endregion

import-History