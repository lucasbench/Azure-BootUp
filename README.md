# Azure-BootUp
KK-course-exercise:
ToSo Construction Inc is in the early stages of determining if they can effectively use Azure for some of their workloads. There are two projects they would like you to work on: a picture upload application and a load balanced VM web server solution. For both solutions, they require:

As much of the implementation as possible should be done with Bicep templates. Bicep templates may or may not use a parameter file. Deployment should be triggered by Azure PowerShell or Azure CLI.
A custom role should be designed per project that includes the least permissions required to do basic troubleshooting on the solution: stop, start, restart, whatever else you think may be valuable.
Resource names should follow a naming convention.
Best practices as far as the usage of resource groups should be followed.
Worry about deploying more than the production environment only if you have the time.
You should include a mechanism for monitoring each solution to confirm that it can do what it is designed to do.

Picture Upload Application:
Use the sample application code here: App code (https://github.com/KonTheCat/KonTheCat_BlobImageUploader) (This will be updated to be a simpler version of this application that has no interactions with Azure Cognitive Services.)
Deploy at least two different instances of the app, use a service for load balancing.
Use a custom DNS name for the front-end IP of the load balancer.
Ensure that no credentials are saved in code or environment configuration as a part of this project.
Implement a mechanism for automatically decreasing the cost of storage of images not modified for more than 90 days. The storage cost needs to be as small as possible while still providing immediate accessibility to the files.

