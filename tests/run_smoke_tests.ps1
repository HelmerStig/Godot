[CmdletBinding()]
param(
	[string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
	$settingsPath = Join-Path $ProjectRoot ".vscode\settings.json"
	if (Test-Path -LiteralPath $settingsPath) {
		$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
		$GodotPath = $settings.'godotTools.editorPath.godot4'
	}
}

if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath)) {
	foreach ($commandName in @("godot", "godot4")) {
		$command = Get-Command $commandName -ErrorAction SilentlyContinue
		if ($null -ne $command) {
			$GodotPath = $command.Source
			break
		}
	}
}

if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath)) {
	throw "Godot non trovato. Passa il percorso con -GodotPath 'C:\path\Godot.exe'."
}

$suites = @("input", "arianna", "mangler", "combat", "arena")
$failedSuites = @()
$totalPassed = 0
$totalFailed = 0

foreach ($suite in $suites) {
	$logPath = Join-Path $ProjectRoot ".godot\test-$suite.log"
	if (Test-Path -LiteralPath $logPath) {
		Remove-Item -LiteralPath $logPath
	}
	$arguments = @(
		"--headless",
		"--path", "`"$ProjectRoot`"",
		"--script", "res://tests/test_$suite.gd",
		"--log-file", "`"$logPath`""
	)

	$process = Start-Process `
		-FilePath $GodotPath `
		-ArgumentList $arguments `
		-WindowStyle Hidden `
		-Wait `
		-PassThru

	$suiteLog = @()
	if (Test-Path -LiteralPath $logPath) {
		$suiteLog = @(Get-Content -Encoding UTF8 -LiteralPath $logPath)
		$suiteLog
	}
	$expectedResult = "{0}_TESTS_OK" -f $suite.ToUpperInvariant()
	$summary = @($suiteLog | Select-String '^TEST_TOTAL: passed=(\d+) failed=(\d+)$')
	$scriptErrors = @($suiteLog | Select-String '^SCRIPT ERROR:')
	$reportedFailures = 0
	if ($summary.Count -eq 1) {
		$totalPassed += [int]$summary[0].Matches[0].Groups[1].Value
		$reportedFailures = [int]$summary[0].Matches[0].Groups[2].Value
		$totalFailed += $reportedFailures
	}
	if ($process.ExitCode -ne 0 -or $suiteLog -notcontains $expectedResult -or $summary.Count -ne 1 -or $scriptErrors.Count -gt 0 -or $reportedFailures -gt 0) {
		$failedSuites += $suite
	}
}

Write-Output "SMOKE_TEST_TOTAL: passed=$totalPassed failed=$totalFailed"
if ($failedSuites.Count -gt 0) {
	Write-Error "Suite fallite: $($failedSuites -join ', ')"
	exit 1
}

Write-Output "SMOKE_TESTS_OK"
exit 0
