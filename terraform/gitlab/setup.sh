#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y curl openssh-server ca-certificates tzdata perl
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo apt-get install -y gitlab-ce

sudo apt update -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
sudo apt update -y
apt-cache policy docker-ce -y
sudo apt install docker-ce -y
sudo systemctl status docker
sudo chmod 777 /var/run/docker.sock

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

#!/bin/bash

GITLAB_URL="https://your.gitlab.instance"
PROJECT_ID="your_project_id"
RUNNER_DESCRIPTION="your_runner_description"

# Get a personal access token with the "api" scope from your GitLab instance
PERSONAL_ACCESS_TOKEN="your_personal_access_token"

# Get the registration token for the specific runner
REGISTRATION_TOKEN=$(curl --header "PRIVATE-TOKEN: $PERSONAL_ACCESS_TOKEN" "$GITLAB_URL/api/v4/projects/$PROJECT_ID/runners" | jq ".[] | select(.description == \"$RUNNER_DESCRIPTION\") | .registration_token")

echo "$REGISTRATION_TOKEN"

# sudo apt-get update
# sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# echo \
#   "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
#   $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# sudo apt-get update
# sudo apt-get install -y docker-ce docker-ce-cli containerd.io
# sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# sudo chmod +x /usr/local/bin/docker-compose