# Informe forense del taller Docker

**Proyecto:** eco-air-backend  
**Estudiante:** 841024  
**Imagen:** `eco-air-backend:1.0.0`  
**Entorno de medición:** Docker Desktop con motor Linux en Windows; 20 de octubre de 2026, hora de Bogotá. Los logs de Docker muestran UTC (21 de octubre).  
**Registro crudo:** `audit_session.log`.

## Alcance y construcción

El repositorio recibido solo contenía un README. Para hacer la práctica ejecutable se creó una aplicación Spring Boot 3.3.4 con Hibernate, H2 en memoria y un endpoint de alertas. No se atribuye a un backend previo. La etapa Maven 3.9.6 con JDK 17 copia primero `pom.xml`, ejecuta `dependency:go-offline` y luego copia `src/`; así, los cambios de fuente conservan la capa de dependencias. La etapa final usa `eclipse-temurin:17-jre-alpine`, copia solo el JAR ejecutable y ejecuta Java como `sensor_user` (UID 10001, grupo `sensorgroup`). `JAVA_TOOL_OPTIONS` limita el heap según el cgroup y usa Serial GC. `OPERATOR_ID` recibe el argumento de construcción.

```bash
docker build --build-arg STUDENT_ID="841024" -t eco-air-backend:1.0.0 .
```

**Resultado:** `BUILD SUCCESS` y exportación de `eco-air-backend:1.0.0`. El registro conserva la salida de la recompilación en caché.

## Tabla de identidad

| Evidencia | Comando | Salida exacta |
|---|---|---|
| Hash de imagen | `docker inspect --format='{{.Id}}' eco-air-backend:1.0.0` | `sha256:c0d483fd40797eb21dabf25c22ad32bb2e6f0ce509fb2995b35c2cf4042e6fb2` |
| Contenedor final | `docker inspect eco_air_active --format='{{.Id}}'` | `bbba1e768bad4572295d74583a1fb4dc770ef13858caab89e04195b2b54a9b62` |
| Operador | `docker exec eco_air_active env \| grep OPERATOR_ID` (equivalente PowerShell: `Select-String`) | `OPERATOR_ID=841024` |
| Usuario efectivo | `docker exec eco_air_active id` | `uid=10001(sensor_user) gid=10001(sensorgroup) groups=10001(sensorgroup)` |

Los ocho hashes de capas del filesystem final, obtenidos con `docker image inspect eco-air-backend:1.0.0 --format='{{json .RootFS.Layers}}'`, son:

```text
sha256:74d97c428c51a828f9051a7a40a53ff1fc99e54fc30323ce36760701b0b7f711
sha256:a152dfd2607b01e7c5b933b98da8c746ed0bd242e4f544ff3afd656fdfc7c7a1
sha256:b9398a5bcfd34ada6c3760ac870b064bf54fb191a502393cbb6a3088f8c9be5b
sha256:76b42b7b749e5cf63c4ef5fe61a878a5f508733d81f12305b29e6320007a49de
sha256:6c0c03120c42828b5d975a2b84e53a9ca0ed58b0b0dab9b6c79f5516ddabce2c
sha256:b7da507efcc9d8cc9f58c88faaa54e30d1935315bd5a9a0812644b5b897c5d8c
sha256:5f70bf18a086007016e948b04aed3b82103a36bea41755bbe3fa63cd68fbe2b6
sha256:ac98264980c2f408e2a4d483412a34a3049c033ed48555bbe3fa63cd68fbe2b6
```

## Historial de capas

Comando: `docker history --human --format "table {{.Size}}\t{{.CreatedBy}}" eco-air-backend:1.0.0`.

```text
SIZE      CREATED BY
0B        ENTRYPOINT ["java" "-jar" "/app/app.jar"]
0B        EXPOSE [8080/tcp]
0B        USER sensor_user
47.5MB    COPY --chown=sensor_user:sensorgroup /build/…
4.1kB     WORKDIR /app
36.9kB    RUN |1 STUDENT_ID=841024 /bin/sh -c addgroup…
0B        ENV OPERATOR_ID=841024 JAVA_TOOL_OPTIONS=-XX…
0B        ARG STUDENT_ID=841024
0B        ENTRYPOINT ["/__cacert_entrypoint.sh"]
12.3kB    COPY --chmod=755 entrypoint.sh /__cacert_ent…
12.3kB    RUN /bin/sh -c set -eux;     echo "Verifying…
141MB     RUN /bin/sh -c set -eux;     ARCH="$(apk --p…
0B        ENV JAVA_VERSION=jdk-17.0.20.1+1
44MB      RUN /bin/sh -c set -eux;     apk add --no-ca…
0B        ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_AL…
0B        ENV PATH=/opt/java/openjdk/bin:/usr/local/sb…
0B        ENV JAVA_HOME=/opt/java/openjdk
0B        CMD ["/bin/sh"]
9.08MB    ADD alpine-minirootfs-3.24.2-x86_64.tar.gz /…
```

El historial de la imagen final contiene el JRE y el JAR, sin capas de instalación de Maven ni de copia de `src/`. Las líneas `CREATED BY` se truncan por el formato de tabla de Docker; la salida completa del comando usado queda en el registro.

## Aislamiento de privilegios y runtime

El primer contenedor activo se inició con `docker run -d --name eco_air_active -p 8080:8080 eco-air-backend:1.0.0`; su ID fue `a5355fd056eff642547d0a613e0ec56b05d38057160ee5ada44b118875603b7a`. Después de calibrar la memoria se reemplazó por el contenedor final de la tabla de identidad.

```text
$ docker top eco_air_active -o pid,user,comm
PID                 USER                COMMAND
2996                10001               java

$ docker exec eco_air_active touch /etc/crontab_fake
touch: cannot touch '/etc/crontab_fake': Permission denied
ExitCode: 1

$ docker exec eco_air_active which mvn
<sin salida>
ExitCode: 1

$ docker exec eco_air_active find / -name "*.java" 2>/dev/null
<sin salida>
ExitCode: 1
```

`docker top` identifica el proceso Java con UID 10001, que corresponde a `sensor_user` según `id`. La escritura en `/etc` fue denegada. `which mvn` no encontró Maven. `find` no devolvió archivos Java; su código 1 se debe a directorios sin permisos de lectura, por lo que se complementa con el Dockerfile: la etapa runtime solo copia el JAR. La comprobación de escritura demuestra el efecto del usuario sin privilegios; no significa que todo el filesystem sea de solo lectura.

## Prueba de 48 MiB

```text
$ docker run -d --name eco_air_crash -m 48m eco-air-backend:1.0.0
28903bcf06ae3a6a96ae2a01fb988c76ae70592add1deaecf7a25f22922d4c2b

$ docker inspect eco_air_crash --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
Status: running | ExitCode: 0 | OOMKilled: false

$ docker inspect eco_air_crash --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
Status: exited | ExitCode: 137 | OOMKilled: true
```

A los 10 segundos, el proceso aún estaba arrancando; la consulta posterior confirmó que el kernel terminó el contenedor por exceder el cgroup. El código 137 corresponde a SIGKILL. Los logs cronometrados muestran que no llegó al mensaje `Started EcoAirApplication`.

## Calibración de memoria

Se probó cada valor con `docker run -d --name <nombre> -m <límite> eco-air-backend:1.0.0`, `docker inspect`, `docker logs --timestamps` y `docker stats --no-stream`. El criterio fue: estado `running`, mensaje de arranque en menos de 15 segundos y consumo estable hasta 45 segundos. El registro contiene cada iteración y el código de salida.

| Límite | Resultado | Arranque (s) | CPU % | MEM USAGE / LIMIT | MEM % |
|---:|---|---:|---:|---|---:|
| 48 MiB | OOMKilled | — | — | — | — |
| 74 MiB | OOMKilled | — | 0.00 | 0B / 0B | 0.00 |
| 87 MiB | inestable: 14.141 s en una prueba y 16.341 s en repetición | 14.141 / 16.341 | 0.14 | 85.21MiB / 87MiB | 97.95 |
| 88 MiB | OOMKilled | — | 0.00 | 0B / 0B | 0.00 |
| 89 MiB | activo a 45 s, repetido | 13.364 / 12.823 | 0.16 | 83.05MiB / 89MiB | 93.31 |
| 90 MiB | activo a 45 s | 13.478 | 0.22 | 83.13MiB / 90MiB | 92.37 |
| 93 MiB | activo a 45 s | 12.259 | 0.13 | 84.84MiB / 93MiB | 91.22 |
| 100 MiB | activo a 45 s | 9.349 | 0.17 | 88.12MiB / 100MiB | 88.12 |
| 152 MiB | activo a 16 s | 5.810 | 0.23 | 131.4MiB / 152MiB | 86.46 |
| 256 MiB | activo a 15 s | 7.046 | 0.12 | 157.9MiB / 256MiB | 61.69 |
| 384 MiB | activo a 15 s | 4.756 | 0.17 | 167.4MiB / 384MiB | 43.59 |
| 512 MiB | activo a 15 s | 5.134 | 0.13 | 175.3MiB / 512MiB | 34.24 |

**Mínimo observado y repetido que cumplió el criterio en este motor:** **89 MiB**, con resolución de 1 MiB entre 88 y 89. No es un límite portable ni garantiza el mismo tiempo bajo otra carga; 100 MiB mostró más margen. El contenedor final se dejó en 89 MiB para documentar el mínimo solicitado.

## Consumo final calibrado

Comandos y salidas del contenedor final, iniciado con `docker run -d --name eco_air_active -m 89m -p 8080:8080 eco-air-backend:1.0.0`:

```text
$ docker inspect eco_air_active --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
Status: running | ExitCode: 0 | OOMKilled: false

$ docker logs --timestamps eco_air_active | grep "Started EcoAirApplication"
2026-10-21T01:26:03.427397464Z 2026-10-21T01:26:03.426Z  INFO 1 --- [           main] e.universidad.ecoair.EcoAirApplication   : Started EcoAirApplication in 14.234 seconds (process running for 15.006)

$ docker stats --no-stream eco_air_active
CONTAINER ID   NAME             CPU %     MEM USAGE / LIMIT   MEM %     NET I/O       BLOCK I/O       PIDS
bbba1e768bad   eco_air_active   0.16%     82.02MiB / 89MiB    92.16%    872B / 126B   345MB / 424MB   31

$ docker exec eco_air_active env | grep OPERATOR_ID
OPERATOR_ID=841024

$ docker exec eco_air_active wget -qO- http://localhost:8080/alerts
[]
```

El resultado HTTP `[]` indica que la API respondió sin alertas registradas. La base H2 es de memoria y sus datos se pierden al detener el contenedor.
