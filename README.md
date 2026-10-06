# systems-monitor

Monitor de disponibilidad de todos los sistemas.

[Uptime Kuma](https://github.com/louislam/uptime-kuma) en Docker. Revisa los sistemas cada
minuto y avisa por **Telegram** cuando uno se cae y cuando vuelve.

**Corre en esta PC**: vigila mientras la PC esté prendida y Docker Desktop abierto. Si la PC
está apagada, no hay avisos.

## Levantarlo

```bash
docker compose up -d
```

Panel: <http://localhost:3100>. Solo escucha en esta PC. La primera vez pide crear el
usuario administrador.

Con `restart: unless-stopped` arranca solo junto con Docker Desktop.

## Telegram (una sola vez)

1. En Telegram, hablarle a **@BotFather**, mandar `/newbot` y copiar el **token**.
2. Mandarle cualquier mensaje al bot nuevo (sin esto no te puede escribir).
3. En el panel: **Configuración → Notificaciones → Configurar notificación**:
   - Tipo: **Telegram**
   - Bot Token: el del paso 1
   - Chat ID: botón **Obtener automáticamente** (por eso el paso 2)
   - Tildar **Activar por defecto** y **Aplicar a todos los monitores existentes**
   - **Probar** → tiene que llegar un mensaje.

El token queda guardado en la base del monitor (volumen `kuma-datos`), no en archivos de
esta carpeta.

## Agregar un sistema

**Agregar nuevo monitor**, con estos valores base:

| Campo | Valor |
| --- | --- |
| Tipo | HTTP(s) |
| Intervalo | 60 s |
| Reintentos | 2 (avisa recién al tercer fallo seguido: evita falsas alarmas) |
| Método HTTP (en *Avanzado*) | `HEAD` si el sistema lo soporta, si no `GET` |
| Códigos aceptados | `200-399` |

Kuma también avisa cuando un certificado HTTPS está por vencer (*Avanzado → Notificación de
vencimiento del certificado*).

### Sistemas vigilados

| Sistema | URL | Notas |
| --- | --- | --- |
| Mecánica Abel | `https://taller.pcfighter.com.ar/login` | `GET` hasta desplegar el soporte de `HEAD` del router; después, `HEAD` |
| RustDesk — IDs (hbbs) | VPS de RustDesk, puerto `21116` | Tipo **TCP Port**, sin SSL/TLS |
| RustDesk — relay (hbbr) | VPS de RustDesk, puerto `21117` | Tipo **TCP Port**, sin SSL/TLS |
| WordPress de la escuela | `https://escuelasantalucia.edu.ar/wp-login.php` | `GET`. `wp-login.php` necesita la base de datos: si se cae, el monitor lo ve |

## Respaldo

La configuración (monitores, notificaciones, historial) vive en el volumen `kuma-datos`.
Para copiarla:

```bash
docker run --rm -v systems-monitor_kuma-datos:/datos -v "$PWD":/destino alpine \
  tar czf /destino/kuma-respaldo.tgz -C /datos .
```
