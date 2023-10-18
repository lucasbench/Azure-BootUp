import os
from azure.storage.blob import BlobServiceClient, generate_blob_sas, BlobSasPermissions, BlobClient
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.identity import DefaultAzureCredential
from flask import (Flask, redirect, render_template, request,
                   send_from_directory, url_for)
import filetype
from datetime import datetime, timedelta
import uuid
from azure.cognitiveservices.vision.contentmoderator import ContentModeratorClient
import azure.cognitiveservices.vision.contentmoderator.models
from msrest.authentication import CognitiveServicesCredentials
from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient


app = Flask(__name__, instance_relative_config=True)

subscription = os.getenv('lucam').split('+')[0]
account = os.getenv("StorageAccountName")
container = os.getenv("StorageContainerName")
cognitiveAccountName = os.getenv("CognitiveAccountName")

def set_blob_data(data, storageAccountName, storageAccountKey, containerName, blobName):
    blob_service_client = BlobServiceClient(account_url = f"https://{storageAccountName}.blob.core.windows.net", credential = storageAccountKey)
    blob_client = blob_service_client.get_blob_client(container = containerName, blob = blobName)
    blob_client.upload_blob(data, blob_type = "BlockBlob", overwrite = True)

def get_primary_storage_account_key(storageAccountName, subscriptionID):
    default_credential = DefaultAzureCredential(exclude_shared_token_cache_credential=True)
    resource_client = ResourceManagementClient(default_credential, subscriptionID)
    resourceList = resource_client.resources.list()
    for item in resourceList:
        if(item.type == 'Microsoft.Storage/storageAccounts' and item.name == storageAccountName):
            resource_group_name = (item.id).split('/')[4]
    storageClient = StorageManagementClient(default_credential, subscriptionID)
    keys = storageClient.storage_accounts.list_keys(resource_group_name, storageAccountName)
    primaryKey = keys.keys[0].value
    return primaryKey

def generate_sas_token(storageAccountName, storageAccountKey, containerName, blobName):
    sas = generate_blob_sas(account_name=storageAccountName,
                            account_key=storageAccountKey,
                            container_name=containerName,
                            blob_name=blobName,
                            permission=BlobSasPermissions(read=True),
                            expiry=datetime.utcnow() + timedelta(hours=2))
    sas_url = f"https://{storageAccountName}.blob.core.windows.net/{containerName}/{blobName}?{sas}" 
    return sas_url

def get_cognitive_service_primary_key(subscriptionID, serviceName):
    default_credential = DefaultAzureCredential()
    resource_client = ResourceManagementClient(default_credential, subscriptionID)
    resourceList = resource_client.resources.list()
    for item in resourceList:
        if(item.type == 'Microsoft.CognitiveServices/accounts' and item.name == serviceName):
            resource_group_name = (item.id).split('/')[4]
    
    cognitiveServiceAccount = CognitiveServicesManagementClient(default_credential, subscriptionID)
    keys = cognitiveServiceAccount.accounts.list_keys(resource_group_name, serviceName)
    return keys.key1

def remove_blob_data(storageAccountName, storageAccountKey, containerName, blobName):
    blob_client = BlobClient(account_url = f"https://{storageAccountName}.blob.core.windows.net", credential = storageAccountKey, container_name= containerName, blob_name= blobName)
    blob_client.delete_blob(delete_snapshots="include")

def get_image_moderation_flagged(client, url):
    evaluation = client.image_moderation.evaluate_url_input(
        content_type="application/json",
        cache_image=True,
        data_representation="URL",
        value=url
    )
    return evaluation.result

key = get_primary_storage_account_key(account, subscription)
subscription_key = get_cognitive_service_primary_key(subscription, cognitiveAccountName)
client = ContentModeratorClient(
    endpoint=f'https://{cognitiveAccountName}.cognitiveservices.azure.com/',
    credentials=CognitiveServicesCredentials(subscription_key)
)

@app.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        file = request.files['file']
        if not filetype.is_image(file):
            return '''
	    <!doctype html>
	    <title>Only images</title>
	    <h1>We only accept images at this time</h1>
	    '''
        myuuid = str(uuid.uuid4())
        fileextension = file.filename.rsplit('.',1)[1]
        filename = myuuid + '.' + fileextension
        try:
            set_blob_data(file, account, key, container, filename)
            url = generate_sas_token(account, key, container, filename)
            if get_image_moderation_flagged(client, url):
                remove_blob_data(account, key, container, filename)
                return '''
                <!doctype html>
                <title>Mod ate it</title>
                <h1>Mod Ate It</h1>
                '''
        except Exception:
            print ('Exception=' + Exception) 
            pass
        return '''
	    <!doctype html>
	    <title>File Link</title>
	    <h1>Uploaded File Link</h1>
	    <p>''' + url + '''</p>
	    '''
    return '''
    <!doctype html>
    <title>Upload new File</title>
    <h1>Upload new File</h1>
    <form action="" method=post enctype=multipart/form-data>
      <p><input type=file name=file>
         <input type=submit value=Upload>
    </form>
    '''

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=81)

if __name__ == '__main__':
   app.run()