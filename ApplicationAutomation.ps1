# powershell -ExecutionPolicy Bypass -File "C:\Users\clutch\Documents\Clutch\ScriptCommands\ApplicationAutomation.ps1" -WindowStyle Hidden

Import-Module WebAdministration

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\www\Preview"
$Global:websiteName = "preview"
$Global:parentApp = "preview"  # The parent application name
$watcher.IncludeSubdirectories = $true
$watcher.Filter = ""
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::DirectoryName

function Test-IISWebsite {
    param ([string]$websiteName)
    return ($null -ne (Get-Website -Name $websiteName -ErrorAction SilentlyContinue))
}

function Get-RelativePath {
    param (
        [string]$fullPath,
        [string]$basePath
    )
    return $fullPath.Substring($basePath.Length).TrimStart('\')
}

function New-IISApplicationSetup {
    param (
        [string]$folderPath,
        [string]$websiteName,
        [string]$parentApp
    )
    try {
        # Get the relative path from the monitored folder
        $relativePath = Get-RelativePath -fullPath $folderPath -basePath $watcher.Path
        $pathParts = $relativePath.Split('\')

        # We only want to process if we're in a valid subfolder (e.g., Contact, Thesaurus)
        if ($pathParts.Length -ge 2) {
            $subfolderName = $pathParts[0]  # e.g., Contact
            $newFolderName = $pathParts[-1]  # The newly created folder

            # Construct the application name
            $appPoolName = "$subfolderName`_$newFolderName"
            $applicationPath = "$parentApp/$subfolderName/$newFolderName"

            # Create Application Pool
            $appPool = Get-IISAppPool -Name $appPoolName -ErrorAction SilentlyContinue
            if ($null -eq $appPool) {
                $appPool = New-WebAppPool -Name $appPoolName -ErrorAction Stop
                Set-ItemProperty -Path "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value "v4.0"
                Set-ItemProperty -Path "IIS:\AppPools\$appPoolName" -Name "startMode" -Value "AlwaysRunning"
                Write-Host "Application Pool '$appPoolName' created successfully" -ForegroundColor Green
            }

            # Create IIS Application
            # $sitePath = "IIS:\Sites\$websiteName\$applicationPath"
            $existingApp = Get-WebApplication -Site $websiteName -Name $applicationPath -ErrorAction SilentlyContinue

            if ($null -eq $existingApp) {
                $webApp = New-WebApplication -Site $websiteName -Name $applicationPath -PhysicalPath $folderPath -ApplicationPool $appPoolName
                if ($null -ne $webApp) {
                    Write-Host "IIS Application '$applicationPath' created successfully" -ForegroundColor Green
                }
            }
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-IISApplicationSetup {
    param (
        [string]$folderPath,
        [string]$websiteName,
        [string]$parentApp
    )
    try {
        $relativePath = Get-RelativePath -fullPath $folderPath -basePath $watcher.Path
        $pathParts = $relativePath.Split('\')

        if ($pathParts.Length -ge 2) {
            $subfolderName = $pathParts[0]
            $folderName = $pathParts[-1]

            $appPoolName = "$subfolderName`_$folderName"
            $applicationPath = "$parentApp/$subfolderName/$folderName"

            # Remove Application
            $sitePath = "IIS:\Sites\$websiteName\$applicationPath"
            if (Test-Path $sitePath) {
                Remove-WebApplication -Name $applicationPath -Site $websiteName
                Write-Host "IIS Application '$applicationPath' removed successfully" -ForegroundColor Green
            }

            # Remove Application Pool
            Start-Sleep -Seconds 1
            $appPool = Get-IISAppPool -Name $appPoolName -ErrorAction SilentlyContinue
            if ($null -ne $appPool) {
                Remove-WebAppPool -Name $appPoolName
                Write-Host "Application Pool '$appPoolName' removed successfully" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Register-ObjectEvent $watcher "Created" -Action {
    $fullPath = $Event.SourceEventArgs.FullPath
    if (Test-Path -Path $fullPath -PathType Container) {
        Write-Host "New folder detected: $fullPath" -ForegroundColor Green
        New-IISApplicationSetup -folderPath $fullPath -websiteName $Global:websiteName -parentApp $Global:parentApp
    }
}

Register-ObjectEvent $watcher "Deleted" -Action {
    $fullPath = $Event.SourceEventArgs.FullPath
    Write-Host "Folder deleted: $fullPath" -ForegroundColor Yellow
    Remove-IISApplicationSetup -folderPath $fullPath -websiteName $Global:websiteName -parentApp $Global:parentApp
}

try {
    if (-not (Test-IISWebsite -websiteName $Global:websiteName)) {
        throw "Website '$Global:websiteName' does not exist in IIS"
    }
    Write-Host "Monitoring folder changes in $($watcher.Path)" -ForegroundColor Cyan
    while ($true) { Start-Sleep -Seconds 1 }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    $watcher.Dispose()
    Get-EventSubscriber | Unregister-Event
}