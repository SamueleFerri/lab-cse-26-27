# Hadoop and Spark are copied from their official images on Docker Hub: much faster than
# the Apache mirrors, and cached locally like any other image.
# Any version with a tag on https://hub.docker.com/r/apache/hadoop and https://hub.docker.com/r/apache/spark works
ARG HADOOP_VERSION=3.4.0
ARG SPARK_VERSION=4.2.0
# apache/hadoop is published for amd64 only: its files are Java (plus x86 native libs, which
# Hadoop replaces with its Java implementations on arm64), so the same copy works on every platform
FROM --platform=linux/amd64 apache/hadoop:${HADOOP_VERSION} AS hadoop
FROM apache/spark:${SPARK_VERSION} AS spark

FROM ubuntu:24.04   

# Parameterizable build arguments with default values (no .env required)
ARG SCALA_VERSION=2.13.17
ARG GRADLE_VERSION=9.8.0

ARG HADOOP_HOME_DIR=/opt/hadoop
ARG SPARK_HOME_DIR=/opt/spark
ARG SCALA_HOME_DIR=/opt/scala
ARG GRADLE_HOME_DIR=/opt/gradle
ARG WORKSPACE_DIR=/workspace

# Expose directories and versions as runtime environment variables
ENV HADOOP_HOME=${HADOOP_HOME_DIR}
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV SPARK_HOME=${SPARK_HOME_DIR}
ENV SPARK_CONF_DIR=${SPARK_HOME}/conf
ENV SCALA_HOME=${SCALA_HOME_DIR}
ENV GRADLE_HOME=${GRADLE_HOME_DIR}
# Symlink created after the JDK install: the real path depends on the architecture (amd64, arm64)
ENV JAVA_HOME=/usr/lib/jvm/java-25
ENV WORKSPACE=${WORKSPACE_DIR}

# Global PATH and shared library configuration
ENV PATH=${SCALA_HOME}/bin:${GRADLE_HOME}/bin:${SPARK_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${JAVA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native:${HADOOP_HOME}/share/hadoop/common:${LD_LIBRARY_PATH}

# PySpark interactive shell configuration for Jupyter Notebook integration
ENV PYSPARK_PYTHON=/usr/bin/python3
ENV PYSPARK_DRIVER_PYTHON=jupyter
ENV PYSPARK_DRIVER_PYTHON_OPTS="notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=${WORKSPACE_DIR}"

# Install core utilities, OpenSSH, Python 3, pip, and OpenJDK in a single layer
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget \
    curl \
    sudo \
    gpg \
    git \
    nano \
    unzip \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    openjdk-25-jdk && \
    ln -s /usr/lib/jvm/java-25-openjdk-$(dpkg --print-architecture) ${JAVA_HOME} && \
    rm -rf /var/lib/apt/lists/*

# Hadoop and Spark from the stages at the top of the file
COPY --from=hadoop --chown=root:root /opt/hadoop ${HADOOP_HOME}
COPY --from=spark --chown=root:root /opt/spark ${SPARK_HOME}

# Download and extract Scala (via GitHub Releases)
RUN mkdir -p ${SCALA_HOME} && \
    curl -fSL "https://github.com/scala/scala/archive/refs/tags/v${SCALA_VERSION}.tar.gz" -o /tmp/scala.tar.gz || \
    curl -fSL "https://downloads.typesafe.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" -o /tmp/scala.tar.gz || \
    curl -fSL "https://github.com/scala/scala/releases/download/v${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" -o /tmp/scala.tar.gz && \
    tar -xzf /tmp/scala.tar.gz -C ${SCALA_HOME} --strip-components=1 && \
    rm /tmp/scala.tar.gz

# Install Gradle (official binary distribution)
RUN curl -fSL -o /tmp/gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" && \
    unzip -q /tmp/gradle.zip -d /tmp && \
    mv /tmp/gradle-${GRADLE_VERSION} ${GRADLE_HOME} && \
    rm /tmp/gradle.zip

RUN echo "hello"
# Spark defaults:
# - applications run on the standalone cluster of docker-compose.yml
# - each application gets 2 one-core executors (one per worker), so two notebooks can run together
# - event logs for the Spark History Server
RUN mkdir -p /tmp/spark-events ${SPARK_CONF_DIR} && \
    printf '%s\n' \
        'spark.master spark://spark-master:7077' \
        'spark.executor.cores 1' \
        'spark.cores.max 2' \
        'spark.eventLog.enabled true' \
        'spark.eventLog.dir file:///tmp/spark-events' \
        'spark.history.fs.logDirectory file:///tmp/spark-events' \
        > ${SPARK_CONF_DIR}/spark-defaults.conf

# Copy requirements file and install Python packages (including Jupyter and PySpark dependencies)
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Persist environment variables for non-login shells and SSH sessions
RUN echo "PATH=\"${PATH}\"" >> /etc/environment && \
    echo "JAVA_HOME=\"${JAVA_HOME}\"" >> /etc/environment && \
    echo "HADOOP_HOME=\"${HADOOP_HOME}\"" >> /etc/environment && \
    echo "HADOOP_CONF_DIR=\"${HADOOP_CONF_DIR}\"" >> /etc/environment && \
    echo "LD_LIBRARY_PATH=\"${LD_LIBRARY_PATH}\"" >> /etc/environment && \
    echo "SPARK_HOME=\"${SPARK_HOME}\"" >> /etc/environment && \
    echo "SPARK_CONF_DIR=\"${SPARK_CONF_DIR}\"" >> /etc/environment && \
    echo "SCALA_HOME=\"${SCALA_HOME}\"" >> /etc/environment && \
    echo "GRADLE_HOME=\"${GRADLE_HOME}\"" >> /etc/environment && \
    echo "PYSPARK_PYTHON=\"${PYSPARK_PYTHON}\"" >> /etc/environment && \
    echo "WORKSPACE=\"${WORKSPACE}\"" >> /etc/environment

# Expose ports for Jupyter Server
EXPOSE 8888

# Set working directory inside the container
WORKDIR ${WORKSPACE_DIR}

# Execute user setup script and keep SSH server running in the foreground
ENTRYPOINT ["/bin/bash"]