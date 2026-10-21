$log = Join-Path (Split-Path $PSScriptRoot -Parent) 'audit_session.log'
Start-Transcript -Path $log -Append
try {
    Write-Host 'docker image inspect eco-air-backend:1.0.0 --format={{.Id}}'
    docker image inspect eco-air-backend:1.0.0 --format='{{.Id}}'
    Write-Host 'docker image inspect eco-air-backend:1.0.0 --format={{json .RootFS.Layers}}'
    docker image inspect eco-air-backend:1.0.0 --format='{{json .RootFS.Layers}}'
    Write-Host 'docker rm -f eco_air_active'
    docker rm -f eco_air_active
    Write-Host 'docker run -d --name eco_air_active -m 89m -p 8080:8080 eco-air-backend:1.0.0'
    docker run -d --name eco_air_active -m 89m -p 8080:8080 eco-air-backend:1.0.0
    Start-Sleep -Seconds 15
    Write-Host "docker inspect eco_air_active --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
    docker inspect eco_air_active --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
    Write-Host 'docker stats --no-stream eco_air_active'
    docker stats --no-stream eco_air_active
    Start-Sleep -Seconds 30
    Write-Host "docker inspect eco_air_active --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
    docker inspect eco_air_active --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
    Write-Host 'docker top eco_air_active -o pid,user,comm'
    docker top eco_air_active -o pid,user,comm
    Write-Host 'docker exec eco_air_active env | Select-String OPERATOR_ID'
    docker exec eco_air_active env | Select-String OPERATOR_ID
    Write-Host "docker logs --timestamps eco_air_active | Select-String 'Started EcoAirApplication'"
    docker logs --timestamps eco_air_active 2>&1 | Select-String 'Started EcoAirApplication'
    Write-Host 'docker stats --no-stream eco_air_active'
    docker stats --no-stream eco_air_active
    Write-Host 'docker exec eco_air_active wget -qO- http://localhost:8080/alerts'
    docker exec eco_air_active wget -qO- http://localhost:8080/alerts
    Write-Host 'docker inspect eco_air_active --format={{.Id}}'
    docker inspect eco_air_active --format='{{.Id}}'
}
finally {
    Stop-Transcript
}
