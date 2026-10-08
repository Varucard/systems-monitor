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
| VPN MikroTik (L2TP/IPsec) | — | Tipo **Push**. Opcional, ver [Chequeo de VPN](#chequeo-de-vpn-opcional) |

## Chequeo de VPN (opcional)

Una VPN L2TP/IPsec va por UDP, y Kuma solo sabe chequear puertos TCP. Para eso está el
contenedor `sonda-vpn`: una vez por hora le manda a la VPN el primer paquete de una
negociación IPsec (UDP 500, con [`ike-scan`](https://github.com/royhills/ike-scan)) y, si
contesta, le late a un monitor **Push** de Kuma. Si deja de latir, llega el aviso.

No hace login: prueba que **el servicio VPN responde desde internet**, por el mismo camino
que usan los usuarios. Cualquier respuesta cuenta, incluso un rechazo de la propuesta de
cifrado. En el log del router aparece una negociación fallida por hora: es esperable.

No arranca con el `docker compose up -d` de siempre. Para activarlo:

1. En el panel, **Agregar nuevo monitor**:
   - Tipo: **Push**
   - Intervalo de latido: **3900 s** (la hora del chequeo más un margen)
   - Reintentos: **0** (`ike-scan` ya reintenta dentro de cada chequeo)
2. Copiar `.env.ejemplo` a `.env` y completar la dirección de la VPN y la URL del Push,
   cambiando `localhost:3100` por `kuma:3001` (la sonda le habla a Kuma por la red de
   Docker). El `.env` no va a git.
3. Levantarlo:

   ```bash
   docker compose --profile vpn up -d --build
   ```

Una vez levantado, `restart: unless-stopped` lo vuelve a arrancar junto con Docker Desktop.
Para ver qué está haciendo: `docker logs monitor-sonda-vpn`.

## Respaldo

La configuración (monitores, notificaciones, historial) vive en el volumen `kuma-datos`.
Para copiarla:

```bash
docker run --rm -v systems-monitor_kuma-datos:/datos -v "$PWD":/destino alpine \
  tar czf /destino/kuma-respaldo.tgz -C /datos .
```
