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

foreach ($suite in $suites) {
	$logPath = Join-Path $ProjectRoot ".godot\test-$suite.log"
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

	if (Test-Path -LiteralPath $logPath) {
		Get-Content -Encoding UTF8 -LiteralPath $logPath
	}
	if ($process.ExitCode -ne 0) {
		$failedSuites += $suite
	}
}

if ($failedSuites.Count -gt 0) {
	Write-Error "Suite fallite: $($failedSuites -join ', ')"
	exit 1
}

Write-Output "SMOKE_TESTS_OK"
exit 0
