$log = Join-Path (Split-Path $PSScriptRoot -Parent) 'audit_session.log'
Start-Transcript -Path $log -Append
try {
    $low = 87
    $high = 100
    while (($high - $low) -gt 1) {
        $limit = [int][Math]::Floor(($low + $high) / 2)
        $name = "eco_air_verify_$limit"
        Write-Host "docker run -d --name $name -m ${limit}m eco-air-backend:1.0.0"
        docker run -d --name $name -m "${limit}m" eco-air-backend:1.0.0
        Start-Sleep -Seconds 15
        Write-Host "docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
        $state15 = docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
        Write-Host $state15
        Write-Host "docker stats --no-stream $name"
        docker stats --no-stream $name
        Start-Sleep -Seconds 30
        Write-Host "docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
        $state45 = docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
        Write-Host $state45
        Write-Host "docker stats --no-stream $name"
        docker stats --no-stream $name
        Write-Host "docker logs --timestamps $name | Select-String 'Started EcoAirApplication'"
        $started = docker logs --timestamps $name 2>&1 | Select-String 'Started EcoAirApplication'
        if ($started) { Write-Host $started }
        $seconds = [double]::PositiveInfinity
        if ($started -and ($started.ToString() -match 'Started EcoAirApplication in ([0-9.]+) seconds')) {
            $seconds = [double]::Parse($Matches[1], [System.Globalization.CultureInfo]::InvariantCulture)
        }
        $pass = $state15 -match 'Status: running' -and $state45 -match 'Status: running' -and $seconds -lt 15
        Write-Host "RESULT limit=${limit}MiB startupSeconds=$seconds stable45s=$pass"
        if ($pass) { $high = $limit } else { $low = $limit }
        Write-Host "docker rm -f $name"
        docker rm -f $name
    }
    Write-Host "RESULT minimumStableTested=${high}MiB resolution=1MiB"
}
finally {
    Stop-Transcript
}
