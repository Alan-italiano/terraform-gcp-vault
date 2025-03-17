#!/bin/bash

echo "Destruindo os recursos"
tofu destroy -auto-approve -var="project_id="
