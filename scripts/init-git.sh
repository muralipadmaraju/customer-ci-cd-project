#!/usr/bin/env bash
set -e
git init
git config user.name "CI/CD Trainee"
git config user.email "trainee@example.com"
git add .
git commit -m "initial customer application"
git branch -M main
git checkout -b develop
git checkout -b release
git checkout develop
git checkout -b feature/customer-search
git branch
git log --oneline --graph --all --decorate
