FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash git wget ca-certificates cron python3 python3-croniter && \
    rm -rf /var/lib/apt/lists/*

COPY docker/tld-updater/run.sh /run.sh
COPY docker/tld-updater/crontab /etc/cron.d/tld-updater
COPY docker/tld-updater/next-run.sh /next-run.sh

RUN chmod +x /run.sh /next-run.sh && \
    chmod 0644 /etc/cron.d/tld-updater && \
    crontab /etc/cron.d/tld-updater && \
    touch /var/log/cron.log

CMD bash -c 'echo "[$(date "+%Y-%m-%d %H:%M:%S")] TLD updater container started"; /next-run.sh >> /var/log/cron.log; cron && tail -f /var/log/cron.log'
