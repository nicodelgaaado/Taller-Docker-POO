$log = Join-Path (Split-Path $PSScriptRoot -Parent) 'audit_session.log'
Start-Transcript -Path $log -Append
try {
    foreach ($limit in 87,100) {
        $name = "eco_air_stable_$limit"
        Write-Host "docker run -d --name $name -m ${limit}m eco-air-backend:1.0.0"
        docker run -d --name $name -m "${limit}m" eco-air-backend:1.0.0
        foreach ($wait in 15,15,15) {
            Start-Sleep -Seconds $wait
            Write-Host "docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'"
            docker inspect $name --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
            Write-Host "docker stats --no-stream $name"
            docker stats --no-stream $name
        }
        Write-Host "docker logs --timestamps $name | Select-String 'Started EcoAirApplication'"
        docker logs --timestamps $name 2>&1 | Select-String 'Started EcoAirApplication'
        Write-Host "docker rm -f $name"
        docker rm -f $name
    }
}
finally {
    Stop-Transcript
}
