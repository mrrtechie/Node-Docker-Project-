#!/bin/bash

################################################################################
# Jenkins Installation Script for Amazon Linux 2023
# Compatible with t2.micro/t3.micro instances
# Includes: Jenkins, Java 17, Git, and all dependencies
# With automatic fallback for download failures
################################################################################

set -e  # Exit on any error

echo "========================================================"
echo "Starting Jenkins Installation on Amazon Linux 2023"
echo "========================================================"

# Update system packages
echo "[1/7] Updating system packages..."
sudo dnf update -y

# Install Java 17 (required for Jenkins)
echo "[2/7] Installing Java OpenJDK 17..."
sudo dnf install java-17-amazon-corretto-devel -y

# Verify Java installation
java -version
echo "✓ Java installed successfully!"

# Install Git
echo "[3/7] Installing Git..."
sudo dnf install git -y

# Verify Git installation
git --version
echo "✓ Git installed successfully!"

# Install other useful tools
echo "[4/7] Installing additional tools (wget, fontconfig)..."
sudo dnf install wget fontconfig -y

# Add Jenkins repository with fallback
echo "[5/7] Adding Jenkins repository..."

# Method 1: Try official Jenkins repo
if sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo 2>/dev/null; then
    echo "✓ Jenkins repo added from official source"
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key || {
        echo "Warning: Could not import GPG key, trying alternative..."
        sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io-2023.key
    }
else
    echo "⚠ Official repo unavailable, using alternative method..."
    # Fallback: Create repo file manually
    sudo bash -c 'cat > /etc/yum.repos.d/jenkins.repo << EOF
[jenkins]
name=Jenkins-stable
baseurl=https://pkg.jenkins.io/redhat-stable
gpgcheck=1
EOF'
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key 2>/dev/null || \
    sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io-2023.key
fi

# Install Jenkins with multiple fallback attempts
echo "[6/7] Installing Jenkins..."

# Try dnf install first
if sudo dnf install jenkins -y 2>/dev/null; then
    echo "✓ Jenkins installed via dnf"
else
    echo "⚠ dnf installation failed, trying direct RPM download..."
    
    # Fallback: Download and install RPM directly
    cd /tmp
    
    # Try multiple versions and sources
    JENKINS_VERSIONS=("2.462.3" "2.462.2" "2.462.1" "2.452.4" "2.452.3")
    INSTALLED=false
    
    for VERSION in "${JENKINS_VERSIONS[@]}"; do
        echo "Trying Jenkins version ${VERSION}..."
        
        # Try official mirror first
        if wget https://pkg.jenkins.io/redhat-stable/jenkins-${VERSION}-1.1.noarch.rpm 2>/dev/null; then
            if sudo rpm -ivh jenkins-${VERSION}-1.1.noarch.rpm; then
                INSTALLED=true
                echo "✓ Jenkins ${VERSION} installed successfully!"
                break
            fi
        fi
        
        # Try archives.jenkins.io as backup
        if [ "$INSTALLED" = false ]; then
            if wget https://archives.jenkins.io/redhat-stable/jenkins-${VERSION}-1.1.noarch.rpm 2>/dev/null; then
                if sudo rpm -ivh jenkins-${VERSION}-1.1.noarch.rpm; then
                    INSTALLED=true
                    echo "✓ Jenkins ${VERSION} installed from archives!"
                    break
                fi
            fi
        fi
        
        # Clean up failed downloads
        rm -f jenkins-*.rpm
    done
    
    if [ "$INSTALLED" = false ]; then
        echo "❌ ERROR: Could not install Jenkins from any source"
        echo "Please check your internet connection and try again"
        exit 1
    fi
fi

# Configure Jenkins to use Java 17
echo "Configuring Jenkins to use Java 17..."
sudo bash -c 'cat > /etc/sysconfig/jenkins << EOF
# Jenkins configuration file

# Java options
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Xms512m -Xmx1024m"

# Jenkins user
JENKINS_USER="jenkins"

# Jenkins port (default 8080)
JENKINS_PORT="8080"

# Jenkins home directory
JENKINS_HOME="/var/lib/jenkins"

# Java command
JAVA_CMD="/usr/bin/java"
EOF'

# Reload systemd and start Jenkins
echo "[7/7] Starting Jenkins service..."
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins to start
echo ""
echo "Waiting for Jenkins to initialize (this may take 1-2 minutes)..."
sleep 30

# Check Jenkins status
echo ""
echo "========================================================"
echo "Checking Jenkins status..."
echo "========================================================"
sudo systemctl status jenkins --no-pager || true

# Check if port 8080 is listening
echo ""
echo "Checking if Jenkins is listening on port 8080..."
sudo ss -tulpn | grep 8080 || echo "⚠ Port 8080 not listening yet. Jenkins may still be starting..."

# Wait a bit more and check again
echo "Waiting additional 30 seconds for full startup..."
sleep 30

# Get initial admin password
echo ""
echo "========================================================"
echo "Installation Complete!"
echo "========================================================"
echo ""
echo "Jenkins Details:"
echo "----------------"
echo "Installation Path: /var/lib/jenkins"
echo "Default Port: 8080"
echo "Service User: jenkins"
echo ""

# Get instance IP
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "Web Access:"
echo "-----------"
echo "Jenkins URL: http://${INSTANCE_IP}:8080"
echo ""

# Try to get initial admin password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    echo "🔐 Initial Admin Password:"
    echo "----------------------------"
    echo "${ADMIN_PASSWORD}"
    echo "----------------------------"
    echo ""
    echo "⚠️  SAVE THIS PASSWORD! You'll need it for first login."
else
    echo "⚠️  Initial password not available yet."
    echo "Wait 1-2 minutes, then retrieve it with:"
    echo "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi

echo ""
echo "Java Version:"
echo "-------------"
java -version
echo ""

echo "Git Version:"
echo "------------"
git --version
echo ""

echo "⚠️  IMPORTANT - AWS Security Group Configuration:"
echo "---------------------------------------------------"
echo "Make sure your Security Group allows inbound traffic on:"
echo "  - Port 8080 (TCP) from your IP or 0.0.0.0/0"
echo ""

echo "First Time Setup:"
echo "-----------------"
echo "1. Open: http://${INSTANCE_IP}:8080"
echo "2. Enter the Initial Admin Password shown above"
echo "3. Click 'Install suggested plugins'"
echo "4. Create your first admin user"
echo "5. Start using Jenkins!"
echo ""

echo "Useful Commands:"
echo "----------------"
echo "Check status:        sudo systemctl status jenkins"
echo "Stop Jenkins:        sudo systemctl stop jenkins"
echo "Start Jenkins:       sudo systemctl start jenkins"
echo "Restart Jenkins:     sudo systemctl restart jenkins"
echo "View logs:           sudo tail -f /var/log/jenkins/jenkins.log"
echo "Get admin password:  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""

echo "Jenkins Home Directory:"
echo "-----------------------"
echo "Jobs:        /var/lib/jenkins/jobs/"
echo "Plugins:     /var/lib/jenkins/plugins/"
echo "Workspace:   /var/lib/jenkins/workspace/"
echo "Config:      /var/lib/jenkins/config.xml"
echo ""

echo "Performance Tips for t2.micro/t3.micro:"
echo "----------------------------------------"
echo "- Jenkins may take 2-3 minutes to fully start on micro instances"
echo "- Limit concurrent builds to 1-2"
echo "- Use lightweight plugins only"
echo "- Monitor memory with: free -h"
echo ""

echo "Troubleshooting:"
echo "----------------"
echo "If Jenkins won't start:"
echo "  1. Check logs: sudo journalctl -u jenkins -n 100 --no-pager"
echo "  2. Check Java: java -version"
echo "  3. Check memory: free -h"
echo "  4. Restart: sudo systemctl restart jenkins"
echo ""

echo "If you can't access Jenkins UI:"
echo "  1. Verify port 8080: sudo ss -tulpn | grep 8080"
echo "  2. Check Security Group has port 8080 open"
echo "  3. Check firewall: sudo firewall-cmd --list-all"
echo ""

echo "========================================================"
echo "Installation script completed successfully!"
echo "========================================================"
