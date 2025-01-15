# start a command in a new terminal window
function Start-TerminalAndRun {
    param (
        [string]$command,
        [string]$workingDirectory
    )

    # Temporary files for output, error, and exit code
    $stdoutFile = Join-Path $env:TEMP "stdout_$((Get-Random)).log"
    $stderrFile = Join-Path $env:TEMP "stderr_$((Get-Random)).log"
    $exitCodeFile = Join-Path $env:TEMP "exitcode_$((Get-Random)).log"

    # Command to run in child process
    $childCmd = @"
cd "$workingDirectory"
& $command
echo `$LastExitCode > "$exitCodeFile"
exit `$LastExitCode
"@

    $argumentList = @('-NoProfile', '-NonInteractive', '-Command', $childCmd)

    # Start the process
    $process = Start-Process "powershell.exe" `
        -PassThru `
        -NoNewWindow `
        -RedirectStandardOutput $stdoutFile `
        -RedirectStandardError  $stderrFile `
        -ArgumentList $argumentList

    # Attach note properties for log files
    $process | Add-Member -MemberType NoteProperty -Name StdOutFile -Value $stdoutFile
    $process | Add-Member -MemberType NoteProperty -Name StdErrFile -Value $stderrFile
    $process | Add-Member -MemberType NoteProperty -Name ExitCodeFile -Value $exitCodeFile

    return $process
}

# Start a process and wait for it to exit. Returns true/false for tracking.
function Wait-AndCheckMsBuildProcess {
    param (
        [System.Diagnostics.Process]$Process,
        [string]$BuildName
    )

    try {
        # Wait for the process to exit
        $Process.WaitForExit()

        # Retrieve the exit code from the file
        $exitCode = if (Test-Path $Process.ExitCodeFile) {
            Get-Content $Process.ExitCodeFile | ForEach-Object { [int]$_ }
        }
        else {
            Write-Host "  - WARNING: Exit code file not found! Defaulting to exit code 1 for failure." -ForegroundColor DarkYellow
            -1 # Default to a failure code if file is missing
        }

        # Check the exit code
        if ($exitCode -ne 0) {
            throw "Error code: $exitCode."
        }

        # Success case
        Write-Host "  - COMPLETED dotnet msbuild for $BuildName" -ForegroundColor DarkGray
        return $true
    }
    catch {
        # Handle exceptions and process errors
        Write-Host "  - ERROR occurred during $BuildName build. Exit code: $exitCode `a" -ForegroundColor Red

        # Read both stdout and stderr logs
        $stderrLines = Get-Content $Process.StdErrFile -ErrorAction SilentlyContinue
        $stdoutLines = Get-Content $Process.StdOutFile -ErrorAction SilentlyContinue
        $allLines = $stderrLines + $stdoutLines

        Write-Host "  - Logging errors: " -ForegroundColor Red

        # Look for MSBuild-specific errors
        $msbLines = $allLines | Select-String -Pattern 'error MSB\d+' -CaseSensitive:$false |
            ForEach-Object { $_.Line }

        if ($msbLines) {
            $msbLines | ForEach-Object { Write-Host "    - $_" -ForegroundColor DarkRed }
        }
        else {
            $allLines | ForEach-Object { Write-Host "    - $_" -ForegroundColor DarkRed }
        }

        return $false
    }
    finally {
        # Clean up temporary files
        if (Test-Path $Process.ExitCodeFile) { Remove-Item $Process.ExitCodeFile -Force }
    }
}





# Display a message with a typewriter effect (delay between characters)
function Write-FancyText {
  param (
      [string]$Text,
      [ConsoleColor]$ForegroundColor = 'White',
      [int]$Delay = 40
  )

  $originalColor = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $ForegroundColor

  foreach ($char in $Text.ToCharArray()) {
      Write-Host -NoNewline $char
      Start-Sleep -Milliseconds $Delay
  }

  Write-Host ""
  $Host.UI.RawUI.ForegroundColor = $originalColor
}

# Display a loading spinner
function Show-LoadingSpinner {
  param (
      [int]$Duration = 0,                     # Duration in seconds (0 means no fixed duration)
      [int]$Delay = 150,                      # Delay between frames in milliseconds
      [System.Diagnostics.Process]$Process   # Optional: Process to wait for
  )

  $spinner = @("|", "/", "-", "\") # Spinning characters
  $endTime = if ($Duration -gt 0) { (Get-Date).AddSeconds($Duration) } else { $null }

  while ($true) {
      foreach ($frame in $spinner) {
          # Check if the process has exited or duration has elapsed
          if (($Process -and $Process.HasExited) -or ($endTime -and (Get-Date) -ge $endTime)) {
              break
          }

          # Display the spinner
          Write-Host -NoNewline "`b$frame" -ForegroundColor Cyan  # `b moves cursor back
          Start-Sleep -Milliseconds $Delay
      }

      # Exit if the process has exited or the duration has elapsed
      if (($Process -and $Process.HasExited) -or ($endTime -and (Get-Date) -ge $endTime)) {
          break
      }
  }

  # Clear the spinner after completion
  Write-Host -NoNewline "`b " # Replace spinner with a space
}



# print formatted table
function Show-Table {
  param (
      [array]$Data,
      [array]$Headers,
      [array]$ColumnWidths,
      [array]$Colors
  )

  # Print the header
  for ($i = 0; $i -lt $Headers.Length; $i++) {
      $header = $Headers[$i].PadRight($ColumnWidths[$i])
      Write-Host -NoNewline "$header" -ForegroundColor White
  }
  Write-Host ""


  # Print a divider
  Write-Host ("-" * ($ColumnWidths | Measure-Object -Sum).Sum) -ForegroundColor White

  # Print each row
  foreach ($row in $Data) {
      Start-Sleep -Milliseconds 800  # Delay for each row
      for ($i = 0; $i -lt $Headers.Length; $i++) {
          $key = $Headers[$i]
          $value = $row[$key].ToString().PadRight($ColumnWidths[$i])
          Write-Host -NoNewline "$value" -ForegroundColor $Colors[$i]
      }

      Write-Host ""  # Move to the next line
  }
}


function Get-YesOrNoInput {
    param (
        [string]$PromptMessage
    )

    while ($true) {
        $userInput = Read-Host $PromptMessage
        if ($userInput -eq 'y' -or $userInput -eq 'n') {
            return $userInput
        } else {
            Write-Host "  - Invalid input. Please enter 'y' or 'n'. `a" -ForegroundColor Yellow
        }
    }
}