$ErrorActionPreference = 'Continue'
$log = Join-Path (Split-Path $PSScriptRoot -Parent) 'audit_session.log'
Start-Transcript -Path $log -Append
try {
    Write-Host "docker inspect eco_air_crash --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
    docker inspect eco_air_crash --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'

    $low = 48
    $high = 256
    while (($high - $low) -gt 1) {
        $limit = [int][Math]::Floor(($low + $high) / 2)
        $name = "eco_air_cal_$limit"
        Write-Host "docker run -d --name $name -m ${limit}m eco-air-backend:1.0.0"
        docker run -d --name $name -m "${limit}m" eco-air-backend:1.0.0
        if ($LASTEXITCODE -ne 0) { throw "No se pudo iniciar $name" }
        Start-Sleep -Seconds 16
        Write-Host "docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
        $state = docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
        Write-Host $state
        Write-Host "docker logs --timestamps $name | Select-String 'Started EcoAirApplication'"
        $started = docker logs --timestamps $name 2>&1 | Select-String 'Started EcoAirApplication'
        if ($started) { Write-Host $started }
        Write-Host "docker stats --no-stream $name"
        docker stats --no-stream $name
        $seconds = [double]::PositiveInfinity
        if ($started -and ($started.ToString() -match 'Started EcoAirApplication in ([0-9.]+) seconds')) {
            $seconds = [double]::Parse($Matches[1], [System.Globalization.CultureInfo]::InvariantCulture)
        }
        $pass = $state -match 'Status: running' -and $seconds -lt 15
        Write-Host "RESULT limit=${limit}MiB startupSeconds=$seconds pass=$pass"
        if ($pass) { $high = $limit } else { $low = $limit }
        Write-Host "docker rm -f $name"
        docker rm -f $name
    }
    Write-Host "RESULT minimumTested=${high}MiB resolution=1MiB"
}
finally {
    Stop-Transcript
}
