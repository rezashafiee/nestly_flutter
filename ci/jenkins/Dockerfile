FROM jenkins/jenkins:lts-jdk21

COPY plugins.txt /usr/share/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/ref/plugins.txt
