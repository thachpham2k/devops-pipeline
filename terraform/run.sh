#!/bin/bash

terraform init

terraform fmt --recursive

terraform plan

terraform apply -auto-approve 
