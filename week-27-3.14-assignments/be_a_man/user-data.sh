#!/bin/bash
set -euxo pipefail

# ------------------------------------
# Update all installed packages
# --------------------------------------
yum update -y

# --------------------------------------
# Install basic tools Jenkins/user data may need
# --------------------------------------
yum install -y wget git fontconfig

# --------------------------------------
# Add the Jenkins repository to yum sources
# --------------------------------------
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/rpm-stable/jenkins.repo

# --------------------------------------
# Import Jenkins repo key
# --------------------------------------
rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key

# --------------------------------------
# Upgrade all packages (including those from the new Jenkins repo)
# --------------------------------------
yum upgrade -y

# --------------------------------------
# Install Amazon Corretto 21
# --------------------------------------
yum install -y java-21-amazon-corretto

# --------------------------------------
# Make Java 21 the system default
# --------------------------------------
alternatives --set java /usr/lib/jvm/java-21-amazon-corretto.x86_64/bin/java

# --------------------------------------
# Verify Java version during bootstrap
# --------------------------------------
java -version

# --------------------------------------
# Install Jenkins
# --------------------------------------
yum install -y jenkins

# --------------------------------------
# Create plugin list
# --------------------------------------
cat > /var/lib/jenkins/plugins.txt <<'EOF'
aws-credentials
pipeline-aws
terraform
snyk-security-scanner
pipeline-gcp
gcp-java-sdk-auth
github
github-oauth
pipeline-github
git
workflow-aggregator
EOF

# --------------------------------------
# Make sure Jenkins directories exist
# --------------------------------------
mkdir -p /opt
mkdir -p /var/lib/jenkins/plugins

# --------------------------------------
# Skip setup wizard
# --------------------------------------
#mkdir -p /etc/systemd/system/jenkins.service.d

#cat > /etc/systemd/system/jenkins.service.d/override.conf <<'EOF'
#[Service]
#Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
#EOF

# --------------------------------------
# Download Jenkins Plugin Installation Manager Tool
# --------------------------------------
wget -O /opt/jenkins-plugin-manager.jar \
  https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.14.0/jenkins-plugin-manager-2.14.0.jar

# --------------------------------------
# Install plugins and dependencies into Jenkins home
# --------------------------------------
java -jar /opt/jenkins-plugin-manager.jar \
  --war /usr/share/java/jenkins.war \
  --plugin-file /var/lib/jenkins/plugins.txt \
  --plugin-download-directory /var/lib/jenkins/plugins

# --------------------------------------
# Fix ownership of installed plugins
# --------------------------------------
chown -R jenkins:jenkins /var/lib/jenkins

# --------------------------------------
# Enable Jenkins to start at boot
# --------------------------------------
systemctl daemon-reload
systemctl enable jenkins

# --------------------------------------
# Start the Jenkins service
# --------------------------------------
systemctl start jenkins