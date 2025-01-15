. "C:\Users\clutch\Documents\Clutch\ScriptCommands\functions.ps1"

# Initial setup
$zip = $false
$apps = @()
$appEnv = ""

# Parse arguments
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        '-zip' {
            $zip = $true
        }
        '-appEnv' {
            if ($i + 1 -lt $args.Count) {
                $appEnv = $args[$i + 1]
                $i++  # Skip the next argument since we've used it
            }
        }
        '-apps' {
            # Collect all app names following the -apps flag
            for ($j = $i + 1; $j -lt $args.Count; $j++) {
                if ($args[$j].StartsWith('-')) {
                    break
                }
                $apps += $args[$j]
                $i = $j
            }
        }
        default {
            # Handle arguments not preceded by a recognized flag
            $apps += $args[$i]
        }
    }
}


Write-Host "`n"
Write-FancyText "========================================" -ForegroundColor White
Write-FancyText "        INITIATING NEW RELEASE          " -ForegroundColor Red
Write-FancyText "========================================" -ForegroundColor White
Write-Host "`n"

Start-Sleep -Seconds 1

# Define base path
$baseAppPath = "C:\Users\clutch\Documents\Clutch\Apps"

# Define the mapping between short names and full app names
$appMappings = @{
    "civ"    = "Civilian-Fatalities"
    "contact" = "Contact"
    "ff"      = "Firefighter-Fatalities"
    "hotel"   = "Hotel"
    "nfa"     = "NFACourses"
    "pubs"    = "Publications"
    "reg"     = "Registry"
    "thes"    = "Thesaurus"
}

# Define the list of all full app names
$allApps = $appMappings.Values

# If no apps are specified, use the full list
if (-not $apps -or $apps.Count -eq 0) {
    Write-Host -NoNewline "~ No specific apps provided, using all apps. `t" -ForegroundColor Yellow
    Show-LoadingSpinner -Duration 2 -Delay 150
    Write-Host ""  # Add a new line after the spinner

    $apps = $allApps
} else {
    # Convert short names to full names using the mapping
    $apps = $apps | ForEach-Object {
        if ($appMappings.ContainsKey($_)) {
            $appMappings[$_]
        } else {
            $_  # If not a short name, keep the original name
        }
    }

    # Validate the specified apps
    $apps = $apps | Where-Object { $allApps -contains $_ }
    if ($apps.Count -eq 0) {
        Write-Host "~ No valid apps specified, exiting." -ForegroundColor Red
        exit 1
    }

    Write-Host "~ Apps received: `t" -NoNewline -ForegroundColor Yellow
    Show-LoadingSpinner -Duration 2 -Delay 150

    foreach ($app in $apps) {
        Start-Sleep -Milliseconds 250

        # Check if the current app is NOT the last app
        if ($app -ne $apps[$apps.Count - 1]) {
            # Print the app with a bar
            Write-Host -NoNewline " $app |" -ForegroundColor Cyan
        } else {
            Write-Host " $app" -ForegroundColor Cyan
        }

        Write-Host "";
    }


}

Write-Host "~ Using: $(if ($appEnv) { "setup:branch --APP_ENV=${appEnv}" } else { 'setup' }) `t" -NoNewline -ForegroundColor Yellow
Show-LoadingSpinner -Duration 2 -Delay 150
Write-Host ""  # Add a new line after the spinner


if (!$zip) {
    Write-Host "~ Skipping zip files. `t" -NoNewline -ForegroundColor Yellow
} else {
    Write-Host "~ Creating zip files. `t" -NoNewline -ForegroundColor Yellow
}
Show-LoadingSpinner -Duration 2 -Delay 150


$scriptStartTime = Get-Date
$totalApps = $apps.Count
$buildIndex = 1
$zipIndex = 1

Write-Host "`n"

foreach ($app in $apps) {
    Write-Host "Processing $app ($buildIndex/$totalApps)..." -ForegroundColor DarkCyan

    $buildIndex++

    # Start timing for this app
    $appStartTime = Get-Date

    # Define paths for dotnet app
    $dotnetAppPath = Join-Path -Path $baseAppPath -ChildPath "$app\$app"

    try {
        if ($appEnv) {
            # If appEnv is set, only do Branch build with the environment parameter
            $msbuildBranchCommand = "dotnet msbuild -p:DeployOnBuild=true -p:PublishProfile=Properties\PublishProfiles\Branch.pubxml -p:AppEnv=${appEnv}"

            $branchProcess = Start-TerminalAndRun -command "$msbuildBranchCommand" -workingDirectory $dotnetAppPath

            Write-Host "  - dotnet msbuild for Branch started`t" -NoNewline -ForegroundColor DarkGray
            Show-LoadingSpinner -Process $branchProcess

            Write-Host ""  # Add a new line after the spinner

            $branchProcess.WaitForExit()

            Write-Host "  - COMPLETED dotnet msbuild for Branch" -ForegroundColor DarkGray
        } else {
            # If no appEnv, do the original Staging and Production builds

            # Staging
            $msbuildStagingCommand = "dotnet msbuild -p:DeployOnBuild=true -p:PublishProfile=Properties\PublishProfiles\Staging.pubxml"
            $stagingProcess = Start-TerminalAndRun -command "$msbuildStagingCommand" -workingDirectory $dotnetAppPath
            Write-Host "  - dotnet msbuild for Staging started`t" -NoNewline -ForegroundColor DarkGray
            Show-LoadingSpinner -Duration 2 -Delay 150
            Write-Host ""  # Add a new line after the spinner

            $stagingProcess.WaitForExit()

            Write-Host "  - COMPLETED dotnet msbuild for Staging" -ForegroundColor DarkGray

            # Prod
            $msbuildProductionCommand = "dotnet msbuild -p:DeployOnBuild=true -p:PublishProfile=Properties\PublishProfiles\Production.pubxml"
            $productionProcess = Start-TerminalAndRun -command "$msbuildProductionCommand" -workingDirectory $dotnetAppPath
            Write-Host "  - dotnet msbuild for Production`t" -NoNewline -ForegroundColor DarkGray
            Show-LoadingSpinner -Duration 2 -Delay 150
            Write-Host ""  # Add a new line after the spinner

            $productionProcess.WaitForExit()

            Write-Host "  - COMPLETED dotnet msbuild for Production" -ForegroundColor DarkGray
        }

        # Log the time
        $appEndTime = Get-Date
        $appDuration = $appEndTime - $appStartTime
        $minutes = [math]::Floor($appDuration.TotalMinutes)
        $seconds = $appDuration.Seconds
        $minuteLabel = if ($minutes -eq 1) { "minute" } else { "minutes" }
        $secondLabel = if ($seconds -eq 1) { "second" } else { "seconds" }

        Write-Host "Finished $app in $minutes $minuteLabel and $seconds $secondLabel" -ForegroundColor DarkGreen
    }
    catch {
        Write-Host "Error encountered while processing {$app}: $_" -ForegroundColor Red
    }
}

# Define the base path where the folders are located
$baseReleasePath = "C:\Users\clutch\Documents\Clutch\Apps\Releases"


# Creates a zip file for each app inside the apps/APP_NAME/Releases folder using the prod folder
if ($zip -and -not $appEnv) {
    Write-Host "`n"
    Write-FancyText "========================================" -ForegroundColor White
    Write-FancyText "           GENERATING ZIP FILES    " -ForegroundColor Red
    Write-FancyText "========================================" -ForegroundColor White
    Write-Host "`n"

    foreach ($app in $apps) {
        # Map short name to full name
        if ($appMappings.Values -contains $app) {
            Write-Host "Zipping $app ($zipIndex/$totalApps)..." -ForegroundColor DarkCyan

            $zipIndex++

            # Define the paths for the app and client app
            $appReleasesPath = Join-Path -Path $baseAppPath -ChildPath "$app\Releases"
            $clientAppPath = Join-Path -Path $baseAppPath -ChildPath "$app\$app\ClientApp"

            # Define the path to the Production folder
            $productionPath = Join-Path -Path $baseReleasePath -ChildPath "$app\Production"

            # Check if the Production directory exists
            if (Test-Path $productionPath) {
                # Check if the Releases directory exists; if not, create it
                if (-not (Test-Path $appReleasesPath)) {
                    Write-Host "  - Releases directory for $app not found at $appReleasesPath. Creating directory..." -ForegroundColor Yellow
                    New-Item -Path $appReleasesPath -ItemType Directory | Out-Null
                }

                # Read the version from package.json
                $packageJsonPath = Join-Path -Path $clientAppPath -ChildPath "package.json"
                if (Test-Path $packageJsonPath) {
                    $packageJson = Get-Content $packageJsonPath | Out-String | ConvertFrom-Json
                    $version = $packageJson.version

                    # Ask for version increment if needed
                    Write-Host "  - Current version: $version" -ForegroundColor Yellow
                    $incrementVersion = Read-Host "  - Do you want to increment the version number? (y/n)"

                    if ($incrementVersion -eq 'y') {
                        # Ask for new version input
                        $newVersion = Read-Host "  - Enter the new version number (x.x.x)"
                        if ($newVersion -match '^\d+\.\d+\.\d+$') { # Optional: Simple validation for semantic versioning format
                            $packageJson.version = $newVersion
                            $version = $newVersion

                            # Convert the updated JSON object back to a string and write it to the file
                            $packageJson | ConvertTo-Json -Depth 100 | Set-Content -Path $packageJsonPath
                            Write-Host "  - Version updated to $newVersion in package.json" -ForegroundColor DarkGray
                        } else {
                            Write-Host "  - Invalid version format. Using the existing version: $version" -ForegroundColor Yellow
                        }
                    }


                    $zipFileName = "$app" + "_$version.zip"
                } else {
                    Write-Host "  - Package.json not found in $clientAppPath. Skipping $app." -ForegroundColor Yellow
                    continue
                }


                # Define the destination zip file within the app's root releases folder
                $zipFilePath = Join-Path -Path $appReleasesPath -ChildPath $zipFileName

                # Compress the contents of the Production folder into a zip file
                Write-Host "  - Zipping contents into $zipFileName..." -ForegroundColor DarkGray
                Compress-Archive -Path (Join-Path $productionPath '*') -DestinationPath $zipFilePath -Force

                Write-Host "  - $zipFileName created successfully." -ForegroundColor DarkGray

                # Delete the oldest zip file if there are more than 2 zip files in the Releases folder
                $zipFiles = Get-ChildItem -Path $appReleasesPath -Filter "*.zip" | Sort-Object LastWriteTime
                if ($zipFiles.Count -gt 5) {
                    $oldestZipFile = $zipFiles[0]
                    Write-Host "  - Deleting oldest zip file: $($oldestZipFile.Name)..." -ForegroundColor DarkGray
                    Remove-Item -Path $oldestZipFile.FullName -Force
                    Write-Host "  - Oldest zip file $($oldestZipFile.Name) has been deleted." -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  - Production directory for $app not found at $productionPath. Skipping." -ForegroundColor Yellow
            }
        } else {
            Write-Host "App short name '$app' not recognized. Skipping." -ForegroundColor Red
        }
    }
}

# Calculate and log the total time taken for all apps
$scriptEndTime = Get-Date
$scriptDuration = $scriptEndTime - $scriptStartTime
$totalMinutes = [math]::Floor($scriptDuration.TotalMinutes)
$totalSeconds = $scriptDuration.Seconds
$totalMinutesLabel = if ($totalMinutes -eq 1) { "minute" } else { "minutes" }
$totalSecondsLabel = if ($totalSeconds -eq 1) { "second" } else { "seconds" }

Write-Host "All apps finished in $totalMinutes $totalMinutesLabel and $totalSeconds $totalSecondsLabel" -ForegroundColor Cyan
Write-Host "`n"
Start-Sleep -Seconds 1


if ($appEnv) {
    Write-Host "`n"
    Write-FancyText "========================================" -ForegroundColor White
    Write-FancyText "         GENERATING PREVIEW URLs    " -ForegroundColor Red
    Write-FancyText "========================================" -ForegroundColor White
    Write-Host "`n"

    $tableData = @()

    foreach ($app in $apps) {
        $appLower = $app.ToLower()
        $url = "https://usfa-apps.clutch-inc.com/preview/$appLower/$appEnv/catalog/search"

        if ($app -eq "NFACourses") {
            $url = "https://usfa-apps.clutch-inc.com/preview/nfacourses/$appEnv/catalog/search"
        }

        if ($app -eq "Contact") {
            $url = "https://usfa-apps.clutch-inc.com/preview/contact/$appEnv/fief"
        }

        $tableData += @{
            App = $app
            URL = $url
        }
    }

    $headers = @("App", "URL")
    $columnWidths = @(25, 80) # Adjust widths based on data
    $colors = @("Red", "Gray")

    Start-Sleep -Milliseconds 1200
    Show-Table -Data $tableData -Headers $headers -ColumnWidths $columnWidths -Colors $colors
}

