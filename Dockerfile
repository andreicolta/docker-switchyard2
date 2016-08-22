############################################################
# Dockerfile to build Postgresql container images
# Based on Centos
############################################################
FROM centos:centos6
MAINTAINER Switchyard docker image: andrycolt007@gmail.com

#Comment
RUN echo 'Add Epel centos 6 repo'
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

# Install packages necessary to run EAP
RUN yum -y install java-1.8.0-openjdk-devel  unzip

# Comment
RUN echo 'Install net-tools package'
RUN yum install -y rsync passwd  net-tools  openssh-server  python-setuptools && easy_install supervisor

# Update OS packages
RUN yum update -y

RUN curl http://files.amakitu.com/UnlimitedJCEPolicy.zip -o /root/UnlimitedJCEPolicy.zip
RUN unzip /root/UnlimitedJCEPolicy.zip -d /root/
#RUN cp -rf /root/UnlimitedJCEPolicy/*.jar /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91.x86_64/jre/lib/security/

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)
RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

USER jboss

# Set the working directory to jboss' user home directory
WORKDIR /opt/jboss

RUN curl http://files.amakitu.com/jboss-eap-6.4.0.zip -o  /tmp/jboss-eap-6.4.0.zip

RUN unzip /tmp/jboss-eap-6.4.0.zip -d /opt/jboss
# Add EAP_HOME environment variable, to easily upgrade the script for different EAP versions
ENV EAP_HOME /opt/jboss/jboss-eap-6.4

# Add default admin user
RUN ${EAP_HOME}/bin/add-user.sh admin admin123! --silent

# Enable binding to all network interfaces and debugging inside the EAP
RUN echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address=0.0.0.0 -Djboss.bind.address.management=0.0.0.0\"" >> ${EAP_HOME}/bin/standalone.conf

# Change default memory settings
RUN  sed -i 's/-Xms1303m\ -Xmx1303m\ -XX\:MaxPermSize=256m/-Xms512m\ -Xmx4096m\ -XX\:MaxPermSize=512m/g'   ${EAP_HOME}/bin/standalone.conf

# Set the JAVA_HOME variable to make it clear where Java is located
ENV JAVA_HOME /usr/lib/jvm/java

RUN curl http://files.amakitu.com/switchyard-2.1.0.Final-EAP6.4.4.GA.zip -o /tmp/switchyard-2.1.0.Final-EAP6.4.4.GA.zip
RUN unzip -o /tmp/switchyard-2.1.0.Final-EAP6.4.4.GA.zip -d $EAP_HOME
RUN rm -rf /opt/jboss/jboss-eap-6.4/modules/system/layers/soa/org/jbpm
RUN rm -rf /opt/jboss/jboss-eap-6.4/modules/system/layers/soa/org/kie
RUN rm -rf /opt/jboss/jboss-eap-6.4/modules/system/layers/soa/org/mvel
RUN rm -rf /opt/jboss/jboss-eap-6.4/modules/system/layers/soa/org/drools

RUN curl http://files.amakitu.com/newrelic-java-3.23.0.zip -o /tmp/newrelic-java-3.23.0.zip
RUN unzip /tmp/newrelic-java-3.23.0.zip  -d /opt/jboss/jboss-eap-6.4/
RUN cd /opt/jboss/jboss-eap-6.4/newrelic && java -jar newrelic.jar install


#Configure ssh
USER root
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN chkconfig sshd on
RUN service sshd start

#Ports Handling
EXPOSE 22 9990 9999 8080 8787
