$log = Join-Path (Split-Path $PSScriptRoot -Parent) 'audit_session.log'
Start-Transcript -Path $log -Append
try {
    Write-Host 'docker run -d --name eco_air_recheck_89 -m 89m eco-air-backend:1.0.0'
    docker run -d --name eco_air_recheck_89 -m 89m eco-air-backend:1.0.0
    Start-Sleep -Seconds 15
    Write-Host "docker inspect eco_air_recheck_89 --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
    docker inspect eco_air_recheck_89 --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
    Write-Host 'docker stats --no-stream eco_air_recheck_89'
    docker stats --no-stream eco_air_recheck_89
    Start-Sleep -Seconds 30
    Write-Host "docker inspect eco_air_recheck_89 --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
    docker inspect eco_air_recheck_89 --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
    Write-Host 'docker stats --no-stream eco_air_recheck_89'
    docker stats --no-stream eco_air_recheck_89
    Write-Host "docker logs --timestamps eco_air_recheck_89 | Select-String 'Started EcoAirApplication'"
    docker logs --timestamps eco_air_recheck_89 2>&1 | Select-String 'Started EcoAirApplication'
    Write-Host 'docker rm -f eco_air_recheck_89'
    docker rm -f eco_air_recheck_89
}
finally {
    Stop-Transcript
}
