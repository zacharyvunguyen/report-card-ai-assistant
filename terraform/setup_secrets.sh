#!/bin/bash

# Script to populate GCP Secret Manager secrets from .env file
# Run this script after terraform apply

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

ENV_FILE="../.env"
PROJECT_ID="reportcard-rag"

echo -e "\n${YELLOW}===== Populating GCP Secrets from .env file =====${NC}\n"

# Ensure project is set
gcloud config set project $PROJECT_ID > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to set project. Exiting.${NC}"
  exit 1
fi

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}.env file not found at $ENV_FILE. Exiting.${NC}"
  exit 1
fi

# Function to get value from .env file
get_env_value() {
  local key=$1
  grep -E "^${key}=" $ENV_FILE | cut -d= -f2-
}

# Map of secret names to environment variable names
declare -A SECRET_MAP
SECRET_MAP["openai-api-key"]="OPENAI_API_KEY"
SECRET_MAP["llamaparse-api-key"]="LLAMA_PARSE_API_KEY" 
SECRET_MAP["tavily-api-key"]="TAVILY_API_KEY"

# Populate secrets
for secret_name in "${!SECRET_MAP[@]}"; do
  env_var="${SECRET_MAP[$secret_name]}"
  value=$(get_env_value "$env_var")
  
  if [ -z "$value" ]; then
    echo -e "${RED}No value found for $env_var in .env file. Skipping $secret_name.${NC}"
    continue
  fi
  
  # Check if secret exists
  if gcloud secrets describe $secret_name > /dev/null 2>&1; then
    echo -e "${YELLOW}Updating secret: $secret_name${NC}"
    echo -n "$value" | gcloud secrets versions add $secret_name --data-file=- > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}✓ Successfully updated $secret_name with value from $env_var${NC}"
    else
      echo -e "${RED}✗ Failed to update $secret_name${NC}"
    fi
  else
    echo -e "${RED}Secret $secret_name does not exist. Run terraform apply first.${NC}"
  fi
done

echo -e "\n${GREEN}===== Secret Setup Complete =====${NC}\n" 