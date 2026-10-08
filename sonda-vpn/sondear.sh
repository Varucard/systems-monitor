#!/bin/sh
# Le habla IPsec (UDP 500) a la VPN y, si contesta, le late al monitor Push de Kuma.
# Cualquier respuesta cuenta: aunque rechace la propuesta de cifrado, el servicio está vivo.
# Si no contesta no se manda nada: Kuma avisa cuando deja de recibir el latido.

: "${VPN_DIRECCION:?falta VPN_DIRECCION en .env}"
: "${VPN_PUSH_URL:?falta VPN_PUSH_URL en .env}"
INTERVALO="${VPN_INTERVALO:-3600}"

# La URL que copia el panel ya trae ?status=up&msg=OK&ping=: se descarta y se arma la propia.
PUSH="${VPN_PUSH_URL%%\?*}"

while true; do
  if ike-scan -q "$VPN_DIRECCION" | grep -qE 'Handshake returned|Notify message'; then
    curl -fsS "$PUSH?status=up&msg=IKE+OK" >/dev/null && echo "$(date '+%F %T') OK"
  else
    echo "$(date '+%F %T') sin respuesta de $VPN_DIRECCION"
  fi
  sleep "$INTERVALO"
done
