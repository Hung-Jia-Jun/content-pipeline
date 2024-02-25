
from google.cloud import storage
from elasticsearch import Elasticsearch
import os
from datetime import datetime
# get today's date
today = datetime.today().strftime('%Y%m%d')
GCS_BUCKET_NAME = 'content-pipeline-file/output'
ELASTICSEARCH_HOST = 'quickstart-es-http'
ELASTICSEARCH_PORT = 9200
ELASTICSEARCH_SCHEMA = 'https'
ELASTICSEARCH_INDEX = 'test-elasticsearch-index'
ELASTICSEARCH_PASSWORD = os.environ['ELASTICSEARCH_PASSWORD']
gcs_client = storage.Client()
es_client = Elasticsearch(f'{ELASTICSEARCH_SCHEMA}://{ELASTICSEARCH_HOST}:{ELASTICSEARCH_PORT}',
                          verify_certs=False,
                          basic_auth=("elastic", ELASTICSEARCH_PASSWORD))

bucket = gcs_client.bucket(GCS_BUCKET_NAME)
blob_name = f"{today}/part-00000"
blob = bucket.blob(blob_name)
data = blob.download_as_string().decode('utf-8')
blobs = bucket.list_blobs(f'{GCS_BUCKET_NAME}/{today}')

for blob in blobs:
    if not blob.name.endswith('/'):
        print(f"Processing file: {blob.name}")
        data = blob.download_as_string().decode('utf-8')
        for line in data.split('\n'):
            if line.strip():
                word, count = line.split('\t')
                data = {
                    "word": word,
                    "count": count
                }
                es_client.index(index=ELASTICSEARCH_INDEX, body=data)
                print("Data has been successfully written to Elasticsearch.")
