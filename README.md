#### Setup AWS CodeBuild
```   
1. Go to CodeBuild via AWS Management Console and click Create Project.
2. Enter a name for the build project and setup additional configuration if needed.
3. Under the Source subsection, select Github as source provider and select "Repository in my GitHub account"
4. Enter Github repository URL and setup additional configuration if needed.
5. Check the "Webhook - optional" under primary source webhook events. Setup additional configuration if needed.
6. Select Managed image for the environment, Ubuntu as the OS, and aws/codebuild/standard:<highest_version_here>
7. Create a new service role in your AWS account for the build project or existing service role if you already have one.
8. Under "Buildspec" subsection, select "Use a buildspec file". The build project will read from buildspec.yml present in your source repository root directory.
9. Check "CloudWatch logs - optional" and/or "S3 logs - optional" under Logs subsection if you need to access persistent build logs.
10. Your basic CodeBuild project is ready to be created. You can also setup notification for the build project later.
11. Go to the newly created service role in IAM and make sure that it has got all the permissions attached like S3, EC2, ElasticBeanStalk, IAM etc. as desired.
12. CodeBuild project is ready to build the project.
```

### Github Repository structure:
##### [`backend.tf`]
- This Terraform script contains S3 details to store Terraform state. Create an S3 bucket for this and use the details.

##### [`main.tf`]
- Uploads a ZIP file (app.zip) containing the application code to an existing S3 bucket (tf-source-code) with the key app.
- Creates an Elastic Beanstalk application named test-app with a description. Defines an application version by referencing the ZIP file uploaded to S3. IAM Roles:
- Sets up an IAM role (eb-instance-role) and associates it with the Elastic Beanstalk environment. Attaches the AWSElasticBeanstalkWebTier policy to the role. VPC, Subnets, and Internet Gateway:
- Creates a VPC with CIDR 10.0.0.0/16 and an associated internet gateway. Creates 2 subnets in available availability zones with public IP association enabled. Sets up a route table to route traffic from the subnets to the internet gateway. Elastic Beanstalk Environment:
- Creates an Elastic Beanstalk environment named test-app-env using the defined application and application version.
- Configures settings such as EnvironmentType, IamInstanceProfile, VPCId, and Subnets.
- Uses the solution stack - 64bit Amazon Linux 2023 v4.1.0 running Docker.
- Pre-requisites - Ensure that app.zip, containing your application code, is located in the same directory as the Terraform configuration. The S3 bucket tf-source-code should already exist. 
- AWS credentials must be configured to allow Terraform to create resources (double-check build service role for this).

##### [`buildspec.yml`]
- This yml file contains the commands for CodeBuild to execute. (Ref. https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)
- Our script is just downloading Terraform on to the build machine and applying the Terraform scripts.

##### [`app.zip`]
- This zip file contains a simple Web Application running on node.

#### Below are the contents of app.zip:
##### [`app.js`]
- This snippet is a simple Node.js application using the Express.js framework. Here's a breakdown of what it does:
- Import Express: const express = require('express'); loads the Express module.
- Initialize Express: const app = express(); creates an instance of an Express application to set up the server.
- Set Port: const PORT = 8080; declares a constant for the port number on which the server will listen. Port 8080 is specified for this application.
- Define a Route Handler: app.get('/', (req, res) => res.send('Hello from Elastic Beanstalk!!')); defines a route handler for HTTP GET requests to the root URL path ('/'). When the root URL is accessed, it responds with the text 'Hello from Elastic Beanstalk!!'.
- Start the Server: app.listen(PORT, () => console.log(Server running on port ${PORT})); tells the Express app to start listening for incoming connections on the specified port, and when the server starts, it logs a message to the console indicating that the server is running and on which port.
- When this application is deployed, for example on AWS Elastic Beanstalk (as the message implies), it will start a server that listens on port 8080. When someone navigates to the root URL of the server, they will receive a greeting message.

##### [`Dockerfile`]
- The provided Dockerfile is a script used by Docker to create a container image for a Node.js application. Here's what each line in the Dockerfile is doing:
- FROM node:14: This line sets the base image for the container. It's using version 14 of the official Node.js image from Docker Hub. This means your application will run in an environment with Node.js version 14 pre-installed.
- WORKDIR /usr/src/app: This line sets the working directory inside the container to /usr/src/app. All subsequent commands will be run from this directory.
- COPY package*.json ./: This command copies both package.json and package-lock.json (if present) to the root of the working directory inside the container. These files define the project dependencies.
- RUN npm install: This line runs the command npm install in the container, which installs the dependencies defined in the package*.json files.
- COPY . .: This copies all the files from the project directory on the host into the current working directory of the container (/usr/src/app). This includes the app.js file and any other files needed for the application to run.
- EXPOSE 8080: This tells Docker to expose port 8080 inside the container to the host machine. This doesn't actually publish the port; it functions as a form of documentation, to indicate to someone reading the Dockerfile that the application inside the container listens on port 8080.
- CMD [ "node", "app.js" ]: This is the command that will be run by default when the container starts up. It starts the Node.js application with the command node app.js.
- When you build a Docker image using this Dockerfile and then run a container from that image, it will start up a Node.js application listening on port 8080, as defined in the app.js 

##### [`Dockerrun.aws.json`]
- "AWSEBDockerrunVersion": "1": This indicates the version of the AWS Elastic Beanstalk Docker configuration file. Version 1 is used for single-container Docker environments.
- "Ports": This is an array that specifies the port mappings between the host (the EC2 instance running the Docker container) and the Docker container itself.
- "ContainerPort": "8080": This specifies that the Docker container is set up to listen on port 8080. This should match the port that your application inside the container is configured to listen on, as declared by the EXPOSE instruction in your Dockerfile.
- "HostPort": "80": This indicates that the host machine (the EC2 instance) will redirect traffic from port 80 to the container's port 8080. This means that any HTTP traffic coming to the EC2 instance on port 80 will be forwarded to port 8080 on the Docker container, where your application is listening.

##### [`package.json`]
- "name": "sample-app": This sets the name of the application or package. In this case, the application is named "sample-app".
- "version": "1.0.0": This field specifies the current version of the application. It follows semantic versioning, and here it indicates that the app is at version 1.0.0.
- "main": "app.js": This indicates the entry point of the application, which is the app.js file. When the package is run, Node.js will default to loading this file.
- "dependencies": This is an object that lists all of the npm package dependencies required by your application to run. In this case, the application depends on the express package, version 4.17.1 or later (as indicated by the caret ^).
- "express": "^4.17.1": The Express.js framework is specified as a dependency, with a version that is compatible with version 4.17.1. The caret means npm will install the latest minor version release that is compatible with 4.17.1.
- "scripts": This object defines script commands that you can run from the command line using npm. For example, you can start the application by running npm start from the command line.
- "start": "node app.js": This script starts the application using Node.js. It is the command that gets executed to run the app.js file when you issue the npm start command.

