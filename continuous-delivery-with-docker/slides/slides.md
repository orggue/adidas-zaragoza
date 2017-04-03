## Continuous Delivery with Docker
&nbsp;
### Adrian Mouat
<img width="400" src="slides/img/cs-logo-transparent-background.png">
---

## Overview

 - What is CI/CD etc?
 - Why do we need it?
 - Breakdown of the steps in a CI/CD pipeline
 - The Drone CI/CD platform
   - Integrating version control
   - Integrating orchestration
 - Advanced topics
   - Labelling
   - Notification
   - Provenance & Reproducibility
   - Monitoring

---

# What is CI/CD

-

 - CI is Continuous Integration
 - CD is Continuous Delivery
   - _or_
 - Continuous Deployment

-

## Continuous Integration

 - Changes to code are regularly merged into the main codebase
   - Multiple times per day
 - Normally involves a "build server"
 - Commonplace
 - Best understood by what came before...

-

## Integration Hell

 - Developers work separately on features
 - Every x weeks the code is merged
 - Days of pain trying to get it to work
   - Large amount of change
   - Hard to pinpoint where bugs come from
   - Changes conflict with each other
 - Better to have small, regular doses of pain...

-

## Build Server

 - Normally organizations use a build server for CI
 - Automatically checks out the code and builds it
   - either poll version control or use hooks
 - Reports build failures

-

## Continuous Delivery

 - Builds on CI
 - Code _can_ be pushed to production at any time
   - Must go through build & test
 - Often will automatically be deployed to staging

-

## Continuous Deployment

 - Code _is_ pushed to production automatically
 - Thorough build and test steps
 - May still involve staging
   - for integration/system tests
   - must be fully automatic
 - Often uses "Testing in Production"

-

## Unit Testing

 - Small, quick tests within code "units"
 - Table stakes!
 - Fails will stop the build
   
-

## Integration and System Tests

 - Also need to test multiple pieces in unison
 - May want to use staging environment for this

-

## Aside: UI Testing

 - Hard to automate
 - But possible
   - Selenium
 - May require refactoring of code
 - Try to limit where possible
   - Prefer API tests

-

## Testing in Production

 - Lots of problems with staging
   - primarily, it never fully reflects prod
 - Solution is to do testing in production
   - but hide it from users
 - Lots of techniques
   - canaries 
   - A/B & multivariate testing
   - Ramped deployment
   - Blue/Green
   - Shadowing

-

## Release Velocity

Measurement of how long it takes to get a change into production.
Shorter times mean:
 - can roll out features faster
 - can get fixes live faster

---

# Containers meet CI/CD

-

 - Containers have a big impact on CI/CD
 - Images replace code as unit of work
   - testing on level of images
   - images shipped between stages
 - Containers used to implement CI/CD
   - provide isolated, temporary environments
   - great for running tests and builds

-

<img src="slides/img/cicd.png">

-

## Build Stage

 - Developer checks code into version control
 - Build server picks it up
   - Builds Docker images, or fails
   - May be multiple steps in building a single image
 - Passes it on to test

-

## Test Stage

 - Runs unit tests against image
 - Also run system/integration tests
 - Raises interesting questions
   - where do the tests live?
   - should images be able to test themselves?
   - should there be separate test images?
   - should tests be external or injected somehow?

-

 - Need tests to run quickly
  - maintain release velocity
  - run in parallel
 - Test failures will stop build

-

## Push stage

 - Images need to be distributed to production
 - Normally use a "registry" for this purpose
   - may be on-prem or remote
   - can use 3rd party service
   - orchestrator will pull from the registry
   - could also "push" images onto nodes

-

## Scan stage

 - Image is scanned for vulnerabilities
 - Optional, but highly recommended
 - May not be a separate stage
 - Output is usually a report
   - likelihood of vulns and false positives
   - can't stop build

-

## Rollout stage

 - Tell production to use new image
 - Probably roll out slowly to subset
 - Lots of different techniques

-

## Notify

 - Make team aware of new deploy
 - Automatically send message to slack or similar

---

## Use Case Specific

 - Huge variation between organizations
  - CI/CD Platform
     - Jenkins, CircleCI, Travis, Drone.io...
  - Method of Interaction
     - Chatbots, CLI tools, Web apps...
  - Deployment platforms
     - Kubernetes, Mesos, Swarm, ECS...
  - Testing Techniques
     - Unit, integration, system, contract, API, shadowing…
  - Monitoring & Alerting
     - NGINX+, Prometheus, CoScale...
  - In house tooling

-

# The Drone CI/CD Platform

 - Drone itself runs in containers
 - All builds run in containers
   - provides fine-grained control and isolation
 - Goal of being replacement for Jenkins
 - Open Source
   - originally proprietary SaaS

-



