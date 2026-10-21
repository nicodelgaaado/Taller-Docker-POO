# Taller Docker Semana 13

## Construcción

```bash
docker build --build-arg STUDENT_ID="841024" -t eco-air-backend:1.0.0 .
```

## Ejecución

```bash
docker run -d --name eco_air_active -m 89m -p 8080:8080 eco-air-backend:1.0.0
curl http://localhost:8080/alerts
```

El límite de 89 MiB fue el menor que pasó las mediciones de este equipo; 100 MiB dejó más margen y arrancó más rápido. La API permite `GET /alerts` y `POST /alerts` con JSON como `{"sensor":"Norte","message":"PM2.5 alto"}`. H2 usa memoria y reinicia los datos en cada ejecución.

Las salidas exactas de Docker, el hash de la imagen y la calibración de memoria están en `audit_session.log` y `FORENSIC_REPORT.md`. En Windows se puede repetir la auditoría con `powershell -ExecutionPolicy Bypass -File scripts/audit.ps1`; el script requiere que no existan contenedores con los nombres de la práctica al momento de ejecución.
