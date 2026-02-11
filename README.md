End-to-End DevSecOps CI/CD Pipeline for Node.js Application (AWS EC2)
Project Overview
This project demonstrates the implementation of a complete DevSecOps CI/CD pipeline for a Node.js application deployed on AWS EC2.

The pipeline automates:
- Code checkout from Git
- Static code analysis using SonarQube
- Quality Gate validation
- Docker image build
- Container vulnerability scanning using Trivy
- Image push to Docker Hub
- Deployment of containerized application on EC2

The objective was to implement a secure, automated, and production-style deployment workflow.
Tech Stack
- Node.js
- Git
- Jenkins (Pipeline as Code)
- SonarQube (Static Code Analysis)
- Trivy (Container Vulnerability Scanning)
- Docker
- AWS EC2 (Amazon Linux)
Architecture Flow
1. Developer pushes code to GitHub repository.
2. Jenkins pipeline triggers automatically.
3. Source code is analyzed using SonarQube.
4. Pipeline waits for Quality Gate validation.
5. Docker image is built from Dockerfile.
6. Trivy scans the image for vulnerabilities.
7. Image is tagged and pushed to Docker Hub.
8. Application is deployed as a Docker container on EC2.
9. Application becomes accessible via public IP and exposed port.
Jenkins Pipeline Stages
- Clean Workspace – Clears previous build artifacts.
- Checkout Code – Clones repository from Git.
- Code Quality Analysis – Runs SonarQube scanner.
- Quality Gate – Blocks pipeline if quality criteria fail.
- Docker Build – Builds container image.
- Trivy Scan – Scans Docker image for vulnerabilities.
- Tag & Push – Pushes image to Docker Hub.
- Deploy – Runs containerized application on EC2.
Security Implementation
- Integrated SonarQube to detect code smells, bugs, and vulnerabilities.
- Enforced Quality Gates to prevent low-quality code from deployment.
- Integrated Trivy to scan container images before pushing to registry.
- Reviewed and addressed vulnerabilities before deployment.
AWS Setup
- EC2 instance launched (Amazon Linux).
- Docker and Jenkins installed and configured.
- SonarQube deployed using Docker container.
- Security groups configured to allow required ports:
  • 8080 (Jenkins)
  • 9000 (SonarQube)
  • 3000 (Application)
Key Learnings
- End-to-end CI/CD pipeline design
- Integration of security scanning into CI workflow
- Docker image lifecycle management
- AWS-based deployment strategy
- Quality Gate enforcement and secure release process

NOTE : Source code for node-js application was forked from 
https://github.com/devops0014/Zomato-Repo.git
