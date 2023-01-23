#Based on https://stackoverflow.com/questions/43691539/create-jenkins-docker-image-with-pre-configured-jobs
FROM jenkins/jenkins:latest

USER root

RUN apt-get update
RUN apt-get install -y sudo

RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

# Docker
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get remove -ymq runc 
RUN apt-get update && apt-get install -y \
                              apt-transport-https \
                              ca-certificates \
                              curl \
                              gnupg-agent \
                              software-properties-common
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
RUN apt-key fingerprint 0EBFCD88
RUN sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io wget

#Add sshpass for ssh script command line.
RUN apt-get install -y sshpass

#Install Node. Required by SonarQube Analizer
RUN apt update &&  apt install -y nodejs && nodejs -v

#Skip Jenkins Setup Wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

#Update Jenkins to latest version
RUN wget "http://updates.jenkins-ci.org/latest/jenkins.war" -O /usr/share/jenkins/jenkins.war
RUN chmod 664 /usr/share/jenkins/jenkins.war

#Install Plugins 
COPY --chown=jenkins:jenkins plugins/plugins.txt  /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

#Enable acces for jnlp Agents
ADD ref /usr/share/jenkins/

#Create OWASP NVD database path
RUN mkdir -p /home/jenkins/security/owasp-nvd/ && chown jenkins.jenkins -R /home/jenkins

#Add Jenkins to Docker group and "daemon" for Mac
RUN usermod -aG docker,daemon jenkins

#########################################
### Jenkins Configuration And Plugins ###
#########################################
USER jenkins

# Create Admin Account
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy

#SonarQube Server Configuration
ADD --chown=jenkins plugins/hudson.plugins.sonar.SonarGlobalConfiguration.xml /var/jenkins_home/
#SonarQube Runner
ADD --chown=jenkins plugins/hudson.plugins.sonar.SonarRunnerInstallation.xml /var/jenkins_home

#Jenkins Projects
ADD --chown=jenkins jobs /var/jenkins_home/jobs/

