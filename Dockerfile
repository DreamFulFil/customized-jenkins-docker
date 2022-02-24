FROM jenkins/jenkins:latest

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV JENKINS_PLUGIN_MANAGER_VERSION 2.12.3

USER root

# install gosu for a better su+exec command
ARG GOSU_VERSION=1.10
RUN dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
 && curl -L -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
 && chmod +x /usr/local/bin/gosu \
 && gosu nobody true

# install docker and add user "jenkins" to group "docker"
RUN  curl -fsSL https://get.docker.com -o get-docker.sh && \
     sh get-docker.sh && \
     usermod -aG docker jenkins && \
     rm -rf get-docker.sh

# change permissions for docker.sock
RUN  touch /var/run/docker.sock && \
          chown root:docker /var/run/docker.sock

# Setup default admin user
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy

# Download plugin manager and install plugins from list
RUN  curl -L -O https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/${JENKINS_PLUGIN_MANAGER_VERSION}/jenkins-plugin-manager-${JENKINS_PLUGIN_MANAGER_VERSION}.jar && \
     mv jenkins-plugin-manager-${JENKINS_PLUGIN_MANAGER_VERSION}.jar /usr/local/bin/jenkins-plugin-manager-${JENKINS_PLUGIN_MANAGER_VERSION}.jar && \
     rm -rf jenkins-plugin-manager-${JENKINS_PLUGIN_MANAGER_VERSION}.jar
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN  java -jar /usr/local/bin/jenkins-plugin-manager-${JENKINS_PLUGIN_MANAGER_VERSION}.jar --war /usr/share/jenkins/jenkins.war --plugin-file /usr/share/jenkins/ref/plugins.txt --latest=false

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
