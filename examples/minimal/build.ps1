# author: Codex (GPT-6 Astra max)
[CmdletBinding()]
param(
	[string]$CompilerPath
)

$ErrorActionPreference = 'Stop'
# HHC uses a nonzero success code; handle it explicitly, even in PowerShell 7.
$PSNativeCommandUseErrorActionPreference = $false
if ($env:OS -ne 'Windows_NT') {
	throw 'This example uses the Windows HTML Help compiler.'
}

# Prefer an explicit path, then PATH, then common Workshop install directories.
if (-not $CompilerPath) {
	$command = Get-Command hhc.exe -CommandType Application -ErrorAction SilentlyContinue
	if ($command) {
		$CompilerPath = $command.Source
	} else {
		foreach ($programDirectory in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
			if ($programDirectory) {
				$candidate = Join-Path $programDirectory 'HTML Help Workshop\hhc.exe'
				if (Test-Path -LiteralPath $candidate -PathType Leaf) {
					$CompilerPath = $candidate
					break
				}
			}
		}
	}
}
if (-not $CompilerPath -or -not (Test-Path -LiteralPath $CompilerPath -PathType Leaf)) {
	throw 'hhc.exe was not found. Install HTML Help Workshop or pass -CompilerPath with its full path.'
}
$compiler = (Get-Item -LiteralPath $CompilerPath).FullName
$library = Join-Path (Split-Path -Parent $compiler) 'hha.dll'
if (-not (Test-Path -LiteralPath $library -PathType Leaf)) {
	throw 'hha.dll is missing beside hhc.exe. Use a complete HTML Help Workshop installation.'
}

$buildDirectory = Join-Path $PSScriptRoot 'build'
$artifactPath = Join-Path $buildDirectory 'manual.chm'
$logPath = Join-Path $buildDirectory 'compile.log'
New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null

# Only the generated CHM is replaced; an old artifact must not mask a failed build.
if (Test-Path -LiteralPath $artifactPath) {
	Remove-Item -LiteralPath $artifactPath -Force
}

Push-Location -LiteralPath $PSScriptRoot
try {
	Write-Host "Compiler: $compiler"
	$messages = & $compiler '.\manual.hhp' 2>&1
	$compilerExitCode = $LASTEXITCODE
	$messages | Set-Content -LiteralPath $logPath -Encoding UTF8
	$messages | ForEach-Object { Write-Host $_ }

	# HHC 4.74.8702 returns 1 on success. Also check diagnostics and fresh output.
	if ($compilerExitCode -ne 1 -or ($messages -match '(?i)\bHHC\d+\s*:\s*Error\b')) {
		throw "Compiler reported a failure (exit $compilerExitCode). See $logPath"
	}
	$artifact = Get-Item -LiteralPath $artifactPath -ErrorAction SilentlyContinue
	if ($null -eq $artifact -or $artifact.Length -lt 4) {
		throw "No non-empty CHM was produced. See $logPath"
	}
	$stream = [System.IO.File]::OpenRead($artifactPath)
	try {
		$header = New-Object byte[] 4
		[void]$stream.Read($header, 0, 4)
		if ([System.Text.Encoding]::ASCII.GetString($header) -ne 'ITSF') {
			throw 'The output does not have a CHM header.'
		}
	} finally {
		$stream.Dispose()
	}
	Write-Host "Built: $artifactPath ($($artifact.Length) bytes)"
	Write-Host "Log:   $logPath"
} finally {
	Pop-Location
}
exit 0
