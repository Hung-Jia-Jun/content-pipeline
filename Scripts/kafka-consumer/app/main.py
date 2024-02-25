from kafka import KafkaConsumer
from datetime import datetime
from google.cloud import storage

client = storage.Client()
BUCKET_NAME = "content-pipeline-file"
bucket = client.bucket(BUCKET_NAME)
consumer = KafkaConsumer("test-topic",bootstrap_servers=['my-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092'])
for msg in consumer:
    today = datetime.today().strftime('%Y%m%d')
    blob_name = f"{today}/{msg.timestamp}"
    filename = f"{msg.timestamp}"
    with open(filename, 'a') as file:
        file.write(msg.value.decode('utf-8') + '\n')
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(filename)
    print(f"file uploaded to gs://{BUCKET_NAME}/{blob_name}")
    
