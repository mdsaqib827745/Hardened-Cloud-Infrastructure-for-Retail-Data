import os
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, ContentSettings

class BlobManager:
    def __init__(self, account_name: str, container_name: str):
        self.account_url = f"https://{account_name}.blob.core.windows.net"
        self.container_name = container_name
        # DefaultAzureCredential will pick up the Managed Identity on the Azure VM
        self.credential = DefaultAzureCredential()
        self.blob_service_client = BlobServiceClient(self.account_url, credential=self.credential)
        self.container_client = self.blob_service_client.get_container_client(self.container_name)

    def upload_blob(self, blob_name: str, data: bytes):
        """Uploads encrypted bytes to the specified container."""
        blob_client = self.container_client.get_blob_client(blob_name)
        blob_client.upload_blob(data, overwrite=True)
        return blob_client.url

    def download_blob(self, blob_name: str) -> bytes:
        """Downloads bytes from the specified blob."""
        blob_client = self.container_client.get_blob_client(blob_name)
        return blob_client.download_blob().readall()

    def list_blobs(self):
        """Lists all blobs in the container."""
        return self.container_client.list_blobs()

    def delete_blob(self, blob_name: str):
        """Deletes the specified blob."""
        blob_client = self.container_client.get_blob_client(blob_name)
        blob_client.delete_blob()
