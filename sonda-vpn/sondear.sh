#!/bin/sh
# Le habla IPsec (UDP 500) a la VPN y, si contesta, le late al monitor Push de Kuma.
# Cualquier respuesta cuenta: aunque rechace la propuesta de cifrado, el servicio está vivo.
# Si no contesta no se manda nada: Kuma avisa cuando deja de recibir el latido.

: "${VPN_DIRECCION:?falta VPN_DIRECCION en .env}"
: "${VPN_PUSH_URL:?falta VPN_PUSH_URL en .env}"
INTERVALO="${VPN_INTERVALO:-3600}"

# De la URL que copia el panel solo sirve el token: trae 127.0.0.1:3100, que dentro de este
# contenedor no es Kuma, y un ?status=up&msg=OK&ping= que se reemplaza por el propio.
TOKEN="${VPN_PUSH_URL#*/api/push/}"
TOKEN="${TOKEN%%\?*}"
PUSH="http://kuma:3001/api/push/$TOKEN"

while true; do
  if ike-scan -q "$VPN_DIRECCION" | grep -qE 'Handshake returned|Notify message'; then
    curl -fsS "$PUSH?status=up&msg=IKE+OK" >/dev/null && echo "$(date '+%F %T') OK"
  else
    echo "$(date '+%F %T') sin respuesta de $VPN_DIRECCION"
  fi
  sleep "$INTERVALO"
done
