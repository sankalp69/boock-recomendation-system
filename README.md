Deployment on Google Cloud Platform (GCP)
Follow these steps to get your Streamlit application running on a GCP Compute Engine instance and accessible via its external IP address.

Prerequisites
A Google Cloud Platform account with an active project.
The gcloud CLI installed and authenticated on your local machine with sufficient permissions (at least Compute Instance Admin and Compute Network Admin roles).
Familiarity with SSH into a Compute Engine instance.
1. Create a GCP Compute Engine Instance
If you don't already have one, create a new VM instance. Ensure it's in the asia-south1-c zone (or your preferred zone) and has enough resources (e.g., e2-medium or e2-small for a basic app).

When creating the instance, make sure you assign a Network tag to it. For this guide, we'll use streamlit-app.

Via gcloud CLI (from your local machine):

Bash

gcloud compute instances create instance-streamlit-app \
    --project=[YOUR_PROJECT_ID] \
    --zone=asia-south1-c \
    --machine-type=e2-medium \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --tags=streamlit-app \
    --boot-disk-size=20GB \
    --metadata=startup-script="#! /bin/bash
        sudo apt-get update -y
        sudo apt-get upgrade -y
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker \$USER # Add current user to docker group
    "
Via Google Cloud Console:

Go to Compute Engine > VM instances.
Click CREATE INSTANCE.
Give it a Name (e.g., instance-streamlit-app).
Choose a Region and Zone (e.g., asia-south1, asia-south1-c).
Select a Machine configuration (e.g., e2-medium).
For Boot disk, choose an Ubuntu LTS image (e.g., Ubuntu 22.04 LTS).
Under Firewall, check Allow HTTP traffic and Allow HTTPS traffic (these create basic firewall rules, but we'll create a specific one for Streamlit).
Expand Management, security, disks, networking, sole tenancy.
Under Networking, find Network tags and add streamlit-app.
Click Create.
2. Configure VM Service Account Scopes (Crucial!)
By default, VMs often have limited permissions. To allow your VM to create firewall rules or perform other gcloud operations (if you run them from within the VM), you need to ensure its service account has sufficient scopes.

You must stop the VM to change its scopes.

Via Google Cloud Console (Recommended for ease):

Go to Compute Engine > VM instances.
Select your instance (instance-streamlit-app) and click STOP. Confirm.
Once stopped, click on the instance name.
Click the EDIT button at the top.
Scroll down to Identity and API access.
Under Access scopes, select "Allow full access to all Cloud APIs".
Click SAVE.
Click START to restart your instance.
Via gcloud CLI (from your local machine, authenticated):

Bash

# Stop the instance
gcloud compute instances stop instance-streamlit-app --zone=asia-south1-c

# Set full access scopes for the service account
gcloud compute instances set-service-account instance-streamlit-app \
    --zone=asia-south1-c \
    --scopes=cloud-platform

# Start the instance
gcloud compute instances start instance-streamlit-app --zone=asia-south1-c
3. SSH into Your Instance and Deploy the App
Once your VM is running and its scopes are updated, connect to it via SSH.

Bash

gcloud compute ssh instance-streamlit-app --zone=asia-south1-c
Once inside the VM, run the following commands:

Bash

# Update package lists and upgrade existing packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your current user to the docker group to run docker commands without sudo
sudo usermod -aG docker $USER
# You will need to log out and log back in for this change to take effect
exit
After logging out, SSH back into your instance to apply the Docker group changes:

Bash

gcloud compute ssh instance-streamlit-app --zone=asia-south1-c
Now, continue with the deployment:

Bash

# Clone your application repository
git clone 'https://github.com/sankalp69/boock-recomendation-system.git'

# Navigate into the application directory
cd boock-recomendation-system

# Build the Docker image for your Streamlit app
# This might take a few minutes depending on your Dockerfile
sudo docker build -t sankalp/stapp:latest .

# Verify the Docker image was built
sudo docker images -a

# Run your Streamlit application in a Docker container
# -d: run in detached mode
# -p 8501:8501: map container port 8501 to host port 8501 (Streamlit's default)
sudo docker run -d -p 8501:8501 sankalp/stapp

# Verify the Docker container is running
sudo docker ps
4. Create a Firewall Rule for Streamlit (Port 8501)
This rule allows external traffic to reach your Streamlit application on port 8501.

Via gcloud CLI (from your local machine, or inside the VM if scopes were updated):

Bash

gcloud compute firewall-rules create allow-streamlit-app \
    --network=default \
    --action=ALLOW \
    --direction=INGRESS \
    --target-tags=streamlit-app \
    --source-ranges=0.0.0.0/0 \
    --rules=tcp:8501 \
    --description="Allows inbound traffic to Streamlit applications on port 8501."
Via Google Cloud Console:

Go to VPC network > Firewall.
Click CREATE FIREWALL RULE.
Name: allow-streamlit-app
Network: default (or your VM's network)
Priority: 1000
Direction of traffic: Ingress
Action on match: Allow
Targets: Specified target tags -> streamlit-app
Source filter: IPv4 ranges -> 0.0.0.0/0 (Allows access from anywhere. Be more restrictive if needed).
Protocols and ports: Specified protocols and ports -> Check tcp and enter 8501 in the "Ports" field.
Click CREATE.
5. Access Your Streamlit Application
Get your VM's External IP Address:

Via gcloud CLI (from your local machine):
Bash

gcloud compute instances list --filter="name=(instance-streamlit-app)" \
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)" \
    --zone=asia-south1-c
Via Google Cloud Console: Go to Compute Engine > VM instances, and look for the External IP column next to your instance-streamlit-app.
Open your web browser:
Paste the external IP address followed by :8501 into your browser's address bar:

http://[YOUR_EXTERNAL_IP_ADDRESS]:8501
You should now see your Streamlit book recommendation system!
