#!/bin/bash
. .env
echo ${GITHUB_API_TOKEN} | docker login ghcr.io -u ${GITHUB_USERNAME} --password-stdin
