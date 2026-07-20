# My DevOps Journey - Day 1-4

A simple Node.js HTTP server, containerized with Docker.

## What this demonstrates
- Basic Node.js HTTP server
- Dockerfile to containerize the app
- Understanding of image builds vs live code changes

## Run locally
node app.js

## Run with Docker
docker build -t myapp .
docker run -d -p 8000:8000 myapp
