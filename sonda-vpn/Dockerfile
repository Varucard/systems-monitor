# Sonda de la VPN L2TP/IPsec: le habla IKE (UDP 500) y le late a Kuma si contesta.
# Imagen propia para no depender de apt-get en cada arranque.
FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ike-scan curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY sondear.sh /sondear.sh
CMD ["sh", "/sondear.sh"]
