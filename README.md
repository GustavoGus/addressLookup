# addressLookup
An Address Lookup LWC and Apex Service Classes that uses getAddress.io API.

## Deployment
The source code is provided as a packaged-styled metadata with an ad-hoc package.xml for it.
You can use Salesforce Workbench to [deploy](https://workbench.developerforce.com/metadataDeploy.php)

### Deployment Steps
1. In the [addressLookup repository](https://github.com/GustavoGus/addressLookup) click on Code button and then in Download ZIP.
2. Access the Salesforce Workbench to [deploy](https://workbench.developerforce.com/metadataDeploy.php) and log with the target org credentials.
3. In the top menu, click on Migration option and then click on Deploy.
4. Select the downloaded Zip from your local, it will have a name like addressLookup-main.zip
5. Use the default settings and deploy. (Review before clicking in which org are you logged into)

### Manual Steps
1. Go to Setup>Permission Sets and find "GetAddressIO Callout Permisions" permission set
2. Click on Manage Assignments and assign it to the users that need to run the integration.
3. Go to Setup>Custom Settings and find "Api Key", click on manage records and you will find the "" record
4. Replace the Key field text "POPULATE WITH THE API-KEY" with the api-key from getAddress.io.
