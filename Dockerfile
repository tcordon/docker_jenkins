#Based on https://stackoverflow.com/questions/43691539/create-jenkins-docker-image-with-pre-configured-jobs
FROM jenkins:latest

USER root

RUN apt-get update
RUN apt-get install -y sudo

RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

# Docker
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install apt-transport-https ca-certificates -y
RUN sh -c "echo deb https://apt.dockerproject.org/repo debian-jessie main > /etc/apt/sources.list.d/docker.list"
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
RUN apt-get update
RUN apt-cache policy docker-engine
RUN apt-get install docker-engine -y

#Skip Jenkins Setup Wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

#Update Jenkins to latest version
RUN wget "http://updates.jenkins-ci.org/latest/jenkins.war" -O /usr/share/jenkins/jenkins.war
RUN chmod 664 /usr/share/jenkins/jenkins.war


#Enable acces for jnlp Agents
ADD ref /usr/share/jenkins/

#########################################
### Jenkins Configuration And Plugins ###
#########################################
USER jenkins

# Create Admin Account
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy

# Minimal Jenkins Plugins
COPY plugins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN cat /usr/share/jenkins/ref/plugins.txt | xargs /usr/local/bin/install-plugins.sh

#SonarQube Server Configuration
ADD --chown=jenkins plugins/hudson.plugins.sonar.SonarGlobalConfiguration.xml /var/jenkins_home/
#SonarQube Runner
ADD --chown=jenkins plugins/hudson.plugins.sonar.SonarRunnerInstallation.xml /var/jenkins_home

#Jenkins Projects
ADD --chown=jenkins jobs /var/jenkins_home/jobs/

