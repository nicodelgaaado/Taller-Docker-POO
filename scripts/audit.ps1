param(
    [string]$Image = 'eco-air-backend:1.0.0',
    [string]$StudentId = '841024'
)

$ErrorActionPreference = 'Continue'
$log = Join-Path (Split-Path $PSScriptRoot -Parent) 'audit_session.log'
Start-Transcript -Path $log -Force
try {
    Write-Host 'docker build --build-arg STUDENT_ID="841024" -t eco-air-backend:1.0.0 .'
    docker build --build-arg "STUDENT_ID=$StudentId" -t $Image .
    if ($LASTEXITCODE -ne 0) { throw 'La construcción falló.' }

    Write-Host 'docker inspect --format={{.Id}} eco-air-backend:1.0.0'
    docker inspect --format='{{.Id}}' $Image
    Write-Host 'docker history --human --format "table {{.Size}}\t{{.CreatedBy}}" eco-air-backend:1.0.0'
    docker history --human --format "table {{.Size}}`t{{.CreatedBy}}" $Image

    Write-Host 'docker run -d --name eco_air_active -p 8080:8080 eco-air-backend:1.0.0'
    docker run -d --name eco_air_active -p 8080:8080 $Image
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear eco_air_active.' }
    Start-Sleep -Seconds 10
    Write-Host 'docker top eco_air_active -o pid,user,comm'
    docker top eco_air_active -o pid,user,comm
    Write-Host 'docker exec eco_air_active id'
    docker exec eco_air_active id
    Write-Host 'docker exec eco_air_active env | Select-String OPERATOR_ID'
    docker exec eco_air_active env | Select-String OPERATOR_ID
    Write-Host 'docker exec eco_air_active touch /etc/crontab_fake'
    docker exec eco_air_active touch /etc/crontab_fake
    Write-Host "ExitCode: $LASTEXITCODE"
    Write-Host 'docker exec eco_air_active which mvn'
    docker exec eco_air_active which mvn
    Write-Host "ExitCode: $LASTEXITCODE"
    Write-Host 'docker exec eco_air_active find / -name "*.java"'
    docker exec eco_air_active find / -name '*.java' 2>$null
    Write-Host "ExitCode: $LASTEXITCODE"
    Write-Host 'docker logs --timestamps eco_air_active | Select-String "Started EcoAirApplication"'
    docker logs --timestamps eco_air_active 2>&1 | Select-String 'Started EcoAirApplication'
    Write-Host 'docker stats --no-stream eco_air_active'
    docker stats --no-stream eco_air_active

    Write-Host 'docker run -d --name eco_air_crash -m 48m eco-air-backend:1.0.0'
    docker run -d --name eco_air_crash -m 48m $Image
    Start-Sleep -Seconds 10
    Write-Host "docker inspect eco_air_crash --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
    docker inspect eco_air_crash --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
    Write-Host 'docker logs --timestamps eco_air_crash'
    docker logs --timestamps eco_air_crash 2>&1

    foreach ($limit in 256,384,512) {
        $name = "eco_air_$limit"
        Write-Host "docker run -d --name $name -m ${limit}m eco-air-backend:1.0.0"
        docker run -d --name $name -m "${limit}m" $Image
        Start-Sleep -Seconds 15
        Write-Host "docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
        docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
        Write-Host "docker logs --timestamps $name | Select-String 'Started EcoAirApplication'"
        docker logs --timestamps $name 2>&1 | Select-String 'Started EcoAirApplication'
        Write-Host "docker stats --no-stream $name"
        docker stats --no-stream $name
    }
}
finally {
    Stop-Transcript
}
