FROM debian:jessie-slim

RUN apt-get update && apt-get install -y jq curl wget git
COPY entrypoint.sh /entrypoint.sh

RUN chmod u+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
