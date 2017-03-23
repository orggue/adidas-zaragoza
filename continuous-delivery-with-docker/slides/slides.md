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
   - Integrating orchestartion
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
   - canarys
   - A/B
   - ...
   - TK fill in 

---

# Why Use CI/CD?

-

"release velocity"

How long does it take to get a change into production?
Lowering this value means you move faster
Moving faster 



Containers vs Code


