# start a command in a new terminal window
function Start-TerminalAndRun {
  param (
      [string]$command,
      [string]$workingDirectory
  )
  $process = Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "cd `"$workingDirectory`"; $command; exit" -PassThru
  return $process
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