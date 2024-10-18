ARG DEBIAN_FRONTEND=noninteractive
ARG FROM=node:lts-bookworm-slim
FROM ${FROM}

ENV RUNNER_NAME=""
ENV RUNNER_TOKEN=""
ENV RUNNER_LABELS=""
ENV RUNNER_REPOSITORY_URL=""
ENV RUNNER_ALLOW_RUNASROOT="1"     
ENV RUNNER_WORK_DIRECTORY="_work"

ENV GITHUB_ACCESS_TOKEN=""
ENV PGLOG log_statement=all
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PIP_ROOT_USER_ACTION=ignore
#ENV TARGET_REPOSITORY=/target/repository
#ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache

#ENV ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER=false
#ENV ACTIONS_RUNNER_CONTAINER_HOOKS=/opt/runner/index.js
ENV ACTIONS_RUNNER_HOOK_JOB_STARTED=/opt/runner/job_started.sh
ENV ACTIONS_RUNNER_HOOK_JOB_COMPLETED=/opt/runner/job_completed.sh

ADD hooks /opt/runner
COPY *.txt /tmp/apt-get/
RUN chmod +x /opt/runner/*.sh
#RUN mkdir -p $AGENT_TOOLSDIRECTORY

LABEL maintainer="me@eq19.com" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.name="tcardonne/github-runner" \
    org.label-schema.description="Dockerized GitHub Actions runner." \
    org.label-schema.url="https://github.com/tcardonne/docker-github-runner" \
    org.label-schema.vcs-url="https://github.com/tcardonne/docker-github-runner" \
    org.label-schema.vendor="Thomas Cardonne" \
    org.label-schema.docker.cmd="docker run -it tcardonne/github-runner:latest"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    sed "s/#.*//" /tmp/apt-get/requirements.txt | xargs apt-get install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Find the most recent 1.1 libssl package in the ubuntu archives
RUN cd /tmp && wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
    dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
  
WORKDIR /home/runner
ADD _site /home/runner/_site
ADD scripts /home/runner/scripts

# Install dependencies
#RUN curl -fsSL https://get.docker.com -o- | sh
RUN gem install faraday-retry github-pages --platform=ruby
RUN npm install --package-lock-only redis talib pg mathjs gauss moxygen && \
    npm ci && npm cache clean --force
    
ARG GH_RUNNER_VERSION
RUN GH_RUNNER_VERSION=${GH_RUNNER_VERSION:-$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | grep tag_name | sed -E 's/.*"v([^"]+)".*/\1/')} && \
    curl -L -O https://github.com/actions/runner/releases/download/v$GH_RUNNER_VERSION/actions-runner-linux-x64-$GH_RUNNER_VERSION.tar.gz && \
    tar -zxf actions-runner-linux-x64-$GH_RUNNER_VERSION.tar.gz && \
    rm -f actions-runner-linux-x64-$GH_RUNNER_VERSION.tar.gz && \
    ./bin/installdependencies.sh && \
    chown -R root: /home/runner && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN chmod +x /home/runner/scripts/*.sh
ENTRYPOINT ["/home/runner/scripts/entrypoint.sh"]

COPY conf/*.conf /etc/supervisor/conf.d/
RUN chmod 644 /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
