# Isolated Linux env for the omph logic suite. omp is a stub (docker/stubs).
FROM debian:stable-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends bash coreutils jq \
 && rm -rf /var/lib/apt/lists/*
COPY . /omph
ENV PATH=/omph/docker/stubs:/omph/bin:$PATH
CMD ["bash", "/omph/test/run.sh"]
