# $apps = $args

# # Define the base path
# $base_path = "C:\Users\clutch\Documents\Clutch\Apps"

# # Define the mapping between short names and full app names
# $appMappings = @{
#     "civ" = "Civilian-Fatalities"
#     "contact" = "Contact"
#     "ff" = "Firefighter-Fatalities"
#     "hotel" = "Hotel"
#     "nfa" = "NFACourses"
#     "pubs" = "Publications"
#     "reg" = "Registry"
#     "thes" = "Thesaurus"
# }
# # Define the list of all full app names
# $allApps = $appMappings.Values

# # If no apps are specified, use the full list
# if (-not $apps -or $apps.Count -eq 0) {
#     Write-Host "No specific apps provided, using all apps." -ForegroundColor Yellow
#     $apps = $allApps
# } else {
#     # Convert short names to full names using the mapping
#     $apps = $apps | ForEach-Object {
#         if ($appMappings.ContainsKey($_)) {
#             $appMappings[$_]
#         } else {
#             $_  # If not a short name, keep the original name
#         }
#     }

#     # Validate the specified apps
#     $apps = $apps | Where-Object { $allApps -contains $_ }
#     if ($apps.Count -eq 0) {
#         Write-Host "No valid apps specified, exiting." -ForegroundColor Red
#         exit 1
#     }
# }

# # Debugging: Output the apps being processed
# Write-Host "Apps recieved: $apps" -ForegroundColor Cyan

# # Commands to run in each directory
# $npm_install = "npm i --quiet --no-progress --no-audit --no-fund @clutch-inc/usfa-ui@latest"

# # Iterate through each app and run commands
# foreach ($app in $apps) {
#     # Construct the full path
#     $client_path = Join-Path -Path $base_path -ChildPath "$app\$app\ClientApp"

#     Write-Host " - Updating $app..." -ForegroundColor DarkGray

#     # Change to the directory
#     Set-Location -Path $client_path

#     # Run npm install and capture errors
#     if (-not (Invoke-Expression $npm_install)) {
#         Write-Host " - Error: npm install failed in $app" -ForegroundColor Red
#         continue
#     }

#     Write-Host " - Finished $app" -ForegroundColor DarkGray
# }

# Write-Host "All apps updated!" -ForegroundColor Cyan



param (
    [string]$v = "@latest",
    [string[]]$apps
)

# Define the base path
$base_path = "C:\Users\clutch\Documents\Clutch\Apps"

# Define the mapping between short names and full app names
$appMappings = @{
    "civ" = "Civilian-Fatalities"
    "contact" = "Contact"
    "ff" = "Firefighter-Fatalities"
    "hotel" = "Hotel"
    "nfa" = "NFACourses"
    "pubs" = "Publications"
    "reg" = "Registry"
    "thes" = "Thesaurus"
}

# Define the list of all full app names
$allApps = $appMappings.Values



# If no apps are specified, use the full list
if (-not $apps -or $apps.Count -eq 0) {
    Write-Host "No specific apps provided, using all apps." -ForegroundColor Yellow
    $apps = $allApps
} else {
    # Convert short names to full names using the mapping
    $apps = $apps | ForEach-Object {
        if ($appMappings.ContainsKey($_)) {
            $appMappings[$_]
        } else {
            $_ # If not a short name, keep the original name
        }
    }

    # Validate the specified apps
    $apps = $apps | Where-Object { $allApps -contains $_ }
    if ($apps.Count -eq 0) {
        Write-Host "No valid apps specified, exiting." -ForegroundColor Red
        exit 1
    }

    Write-Host "Apps received: $apps" -ForegroundColor Cyan
}

# Debugging: Output the apps being processed
Write-Host "Version recieved: $v" -ForegroundColor Cyan


# Define npm command with the specified or default version
$npm_install = "npm i --quiet --no-progress --no-audit --no-fund @clutch-inc/usfa-ui@$v"

# Iterate through each app and run commands
foreach ($app in $apps) {
    # Construct the full path
    $client_path = Join-Path -Path $base_path -ChildPath "$app\$app\ClientApp"

    Write-Host " - Updating $app..." -ForegroundColor DarkGray

    # Change to the directory
    Set-Location -Path $client_path

    # Run npm install and capture errors
    if (-not (Invoke-Expression $npm_install)) {
        Write-Host " - Error: npm install failed in $app" -ForegroundColor Red
        continue
    }

    Write-Host " - Finished $app" -ForegroundColor DarkGray
}

Write-Host "All apps updated!" -ForegroundColor Cyan
