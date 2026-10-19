# TravelMemory — Terraform & Ansible Deployment on AWS

## Project Overview

TravelMemory is a full-stack travel experience application deployed on Amazon Web Services (AWS). This project demonstrates Infrastructure as Code (IaC), configuration management, application deployment, database integration, and web server configuration using Terraform and Ansible.

The application allows users to explore travel experiences and add their own travel memories.

**Key objectives:**
- Provision AWS infrastructure using Terraform.
- Configure and manage EC2 instances using Ansible.
- Deploy a React frontend and Node.js/Express backend.
- Connect the backend to MongoDB Atlas.
- Configure Nginx as a web server and reverse proxy.
- Run the backend as a systemd service.
- Version-control the infrastructure and deployment configuration using Git and GitHub.

## Technology Stack

| Technology | Purpose |
|---|---|
| AWS EC2 | Hosts the application and Ansible control node |
| Terraform | Infrastructure provisioning |
| Ansible | Server configuration and deployment automation |
| Ubuntu Server 24.04 LTS | Operating system |
| React | Frontend |
| Node.js | Backend runtime |
| Express.js | Backend API |
| MongoDB Atlas | Cloud-hosted database |
| Nginx | Web server and reverse proxy |
| systemd | Backend process management |
| Git and GitHub | Source control and project hosting |

## Architecture

```text
                  User / Web Browser
                          |
                          | HTTP :80
                          v
                +-------------------+
                |   AWS EC2 App     |
                |      Server       |
                |                   |
                |       Nginx       |
                |       :80         |
                +---------+---------+
                          |
                +---------+---------+
                |                   |
                v                   v
        React Frontend        /trip API
        Static Build              |
                                  v
                         Node.js / Express
                              :3001
                                  |
                                  v
                         MongoDB Atlas
                         Cloud Database


  Developer / Local Machine
             |
             v
          Terraform
             |
             v
       AWS Infrastructure
             |
             v
       Ansible Control Node
             |
             v
        Application EC2
```

Terraform provisions the AWS infrastructure. Ansible configures the application server, deploys the source code, configures the database connection, builds the frontend, and configures Nginx.

Nginx serves the React application and forwards `/trip` API requests to the backend on `127.0.0.1:3001`. The backend connects to MongoDB Atlas.

## Repository Structure

```text
TravelMemory-Terraform-Ansible/
├── ansible/
│   ├── test-server.yml
│   ├── install-prerequisites.yml
│   ├── deploy-source.yml
│   ├── configure-atlas.yml
│   ├── backend-service.yml
│   └── deploy-frontend.yml
├── report/
├── terraform/
│   ├── .terraform.lock.hcl
│   └── *.tf
├── .gitignore
└── README.md
```

The Terraform directory contains the infrastructure configuration. The Ansible directory contains the playbooks used for configuration and deployment. The report directory contains project documentation and supporting material.

*Note: The Terraform directory may contain additional files not listed individually above.*

## AWS Infrastructure

The deployment uses two EC2 instances.

| Component | Details |
|---|---|
| AWS Region | `us-east-1` |
| Application server | `34.205.75.2` at the time of deployment |
| Application instance ID | `i-0d029e90b1b4d40f2` |
| Ansible control node | `35.153.103.186` at the time of deployment |
| Operating system | Ubuntu Server 24.04 LTS |
| Application web port | TCP 80 |
| Backend port | TCP 3001, internal |
| SSH port | TCP 22 |

Public IP addresses may change if the instances are replaced or recreated.

### Security Group

The application security group was configured with these inbound rules during testing:

- TCP 80 — HTTP access.
- TCP 22 — SSH administration.
- TCP 3000 — restricted to a specific public IP used during testing.

The backend listens on port 3001 and is accessed through Nginx, so it does not need to be publicly exposed for this architecture.

**Security improvement:** Restrict SSH access to a trusted IP address or use a managed access solution. Review all inbound rules before using the deployment in production.

## Prerequisites

Install or configure the following tools:

- Terraform CLI
- AWS CLI
- An AWS account with appropriate IAM permissions
- An SSH key pair for EC2 access
- Ansible on the control node
- Git
- Node.js and npm (installed on the application server by Ansible)
- A MongoDB Atlas account
- A GitHub account

The deployment was tested with Terraform 1.16.4, AWS CLI 2.34.63, Ansible Core 2.16.3, Node.js 18.19.1, and npm 9.2.0. Versions and available packages may change over time.

## Step 1: Provision Infrastructure with Terraform

Open a terminal in the Terraform directory:

```powershell
cd terraform
```

Initialize Terraform:

```powershell
terraform init
```

Validate the configuration:

```powershell
terraform validate
```

Review the proposed changes:

```powershell
terraform plan
```

Apply the configuration:

```powershell
terraform apply
```

Review the plan carefully before approving any infrastructure changes.

Terraform is responsible for creating and managing the AWS resources defined in the configuration. Keep the Terraform state file private and protected.

## Step 2: Configure the Ansible Control Node

Ansible was executed from a separate Ubuntu EC2 control node.

The working Ansible directory on that machine was:

```bash
~/travelmemory-ansible
```

The inventory file used the application server's public IP:

```ini
[travelmemory]
34.205.75.2 ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/travelmemory-key.pem
```

The inventory and private key shown above are examples of the deployment configuration. Keep the actual private key outside the Git repository.

Test connectivity:

```bash
ansible -i inventory.ini travelmemory -m ping
```

A successful ping confirms that Ansible can connect to the target host.

## Step 3: Install Application Prerequisites

The `install-prerequisites.yml` playbook installs the required Git and Node.js tooling on the application server.

Run it from the Ansible control node:

```bash
cd ~/travelmemory-ansible

ansible-playbook -i inventory.ini install-prerequisites.yml
```

Verify the installed tools on the application server:

```bash
node --version
npm --version
git --version
```

## Step 4: Deploy the Application Source Code

The `deploy-source.yml` playbook clones the TravelMemory application source code to:

```text
/opt/TravelMemory
```

The upstream application source used for this deployment is:

https://github.com/UnpredictablePrashant/TravelMemory

Run:

```bash
ansible-playbook -i inventory.ini deploy-source.yml
```

The repository contains separate frontend and backend directories.

## Step 5: Configure MongoDB Atlas

MongoDB Atlas is used as the managed database service.

Configuration steps:

1. Create a MongoDB Atlas project and database deployment.
2. Create a database user with an appropriate password.
3. Configure Atlas network access to permit connections from the application server.
4. Obtain the MongoDB connection URI.
5. Store the connection URI securely on the Ansible control node.
6. Use the `configure-atlas.yml` playbook to configure the backend environment.

The backend environment file on the application server is:

```text
/opt/TravelMemory/backend/.env
```

Its expected structure is:

```dotenv
PORT=3001
MONGO_URI=<YOUR_MONGODB_ATLAS_CONNECTION_URI>
```

Replace the placeholder with the actual URI in the secure environment file. Do not commit real credentials to Git.

Run the playbook:

```bash
ansible-playbook -i inventory.ini configure-atlas.yml
```

The application's backend uses Mongoose to connect to MongoDB Atlas.

**Important:** Ensure the database password is correctly URL-encoded when required by the connection URI format. Do not share the actual URI in logs, screenshots, or public repositories.

## Step 6: Configure the Backend Service

The Node.js backend runs as a systemd service named:

```text
travelmemory-backend.service
```

The service runs from:

```text
/opt/TravelMemory/backend
```

The backend listens on port 3001.

Check its status on the application server:

```bash
sudo systemctl status travelmemory-backend
```

Restart the service if required:

```bash
sudo systemctl restart travelmemory-backend
```

View recent service logs:

```bash
sudo journalctl -u travelmemory-backend -n 100 --no-pager
```

The `backend-service.yml` playbook manages the backend service configuration.

## Step 7: Build and Deploy the React Frontend

The frontend source is located at:

```text
/opt/TravelMemory/frontend
```

The production build is generated in:

```text
/opt/TravelMemory/frontend/build
```

The `deploy-frontend.yml` playbook installs the required dependencies, builds the React application, and configures Nginx.

Run:

```bash
ansible-playbook -i inventory.ini deploy-frontend.yml
```

The frontend uses the same origin for its API requests, allowing Nginx to forward API traffic to the backend.

## Step 8: Configure Nginx

Nginx serves the static React build and acts as a reverse proxy for the backend API.

The deployed configuration follows this design:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /opt/TravelMemory/frontend/build;
    index index.html;

    location /trip {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Validate the configuration:

```bash
sudo nginx -t
```

Check the service:

```bash
sudo systemctl status nginx
```

Reload Nginx after configuration changes:

```bash
sudo systemctl reload nginx
```

## Step 9: Configure the Domain

The domain used for the deployment is:

- `sachinkanak.online`
- `www.sachinkanak.online`

The following DNS records were configured through the domain registrar:

| Type | Host | Value |
|---|---|---|
| A | `@` | `34.205.75.2` |
| CNAME | `www` | `sachinkanak.online` |

DNS changes can take time to propagate. The public IP must remain correct for the records to continue pointing to the application.

The website was verified over HTTP. **HTTPS/TLS is not yet configured** and should be completed before using the site for public production traffic.

## Deployment Verification

The following checks were used to verify the deployment.

### 1. Check the frontend

Open the application in a browser:

- `http://34.205.75.2`
- `http://sachinkanak.online`
- `http://www.sachinkanak.online`

Domain availability depends on DNS propagation and the current EC2 public IP.

### 2. Check the backend health endpoint

```bash
curl -i http://127.0.0.1:3001/hello
```

The `/hello` endpoint should return an HTTP success response.

### 3. Check the API through Nginx

```bash
curl -i http://127.0.0.1/trip/
```

The `/trip/` endpoint should return a response from the backend. When no travel records exist, an empty JSON array may be returned.

### 4. Check the backend service

```bash
sudo systemctl is-active travelmemory-backend
```

Expected result:

```text
active
```

### 5. Check Nginx

```bash
sudo nginx -t
sudo systemctl is-active nginx
```

### 6. Test database persistence

Submit a travel experience through the web application, then refresh the page or retrieve the trips again to verify that the data persists in MongoDB Atlas.

Avoid repeatedly submitting the form while testing, as each successful submission can create another record.

## Troubleshooting

### Ansible cannot connect to the server

Check:

- The EC2 instance is running.
- The inventory contains the correct host address.
- The SSH key path is correct on the control node.
- The security group permits SSH from the connecting machine.
- The target username is correct.

### Backend service fails

Check the service and logs:

```bash
sudo systemctl status travelmemory-backend
sudo journalctl -u travelmemory-backend -n 100 --no-pager
```

Verify that the environment file exists, has the correct permissions, and contains valid configuration.

### MongoDB Atlas connection fails

Check:

- The database username and password.
- The MongoDB connection URI.
- Atlas network access rules.
- Outbound network connectivity.
- TLS and certificate errors in the backend logs.

Never paste the database URI or password into a public issue or GitHub commit.

### Nginx returns a 502 Bad Gateway

Check whether the backend is running and listening on port 3001:

```bash
sudo systemctl status travelmemory-backend
sudo ss -lntp | grep 3001
```

Verify that Nginx proxies `/trip` to `http://127.0.0.1:3001`.

### Frontend changes are not visible

Rebuild the React application and verify that Nginx serves the latest files from the build directory. Clear the browser cache if an older version is still displayed.

## Learning Outcomes

Through this project, I gained hands-on experience with:

- Infrastructure as Code using Terraform.
- Configuration management using Ansible.
- AWS EC2 provisioning and security groups.
- Automated application deployment.
- React production builds.
- Node.js and Express backend hosting.
- MongoDB Atlas connectivity.
- Nginx reverse proxy configuration.
- Linux systemd services.
- Git and GitHub version control.
- Troubleshooting cloud networking and application deployment.

## Project Repository

GitHub repository:

https://github.com/sachindew077-byte/TravelMemory-Terraform-Ansible

Upstream TravelMemory application:

https://github.com/UnpredictablePrashant/TravelMemory

---

**Project status:** The React frontend and Node.js backend were deployed to AWS, MongoDB Atlas persistence was verified, and the application was tested through Nginx. HTTP access was verified; HTTPS configuration remains a future task.
