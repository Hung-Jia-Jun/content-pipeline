'''Example Airflow DAG that creates a Cloud Dataproc cluster, runs the Hadoop
wordcount example, and deletes the cluster.

This DAG relies on three Airflow variables
https://airflow.apache.org/docs/apache-airflow/stable/concepts/variables.html
* gcp_project - Google Cloud Project to use for the Cloud Dataproc cluster.
* gce_region - Google Compute Engine region where Cloud Dataproc cluster should be
  created.
* gcs_bucket - Google Cloud Storage bucket to use for result of Hadoop job.
  See https://cloud.google.com/storage/docs/creating-buckets for creating a
  bucket.
'''

import datetime
import os

from airflow import models
from airflow.providers.google.cloud.operators import dataproc
from airflow.utils import trigger_rule
import datetime

today = datetime.datetime.today().strftime('%Y%m%d')

input_file = f'gs://content-pipeline-file/{today}'
scripts_path = 'gs://content-pipeline-file/Scripts'
mapper = 'mapper.py'
reducer = 'reducer.py'
job_args = {
    'input': input_file,
    'output': f'gs://content-pipeline-file/output/{today}',
    'mapper': mapper,
    'reducer': reducer,
}
PYSPARK_JOB={
    'reference': {'project_id': '{{ var.value.gcp_project }}'},
    'placement': {'cluster_name': 'composer-hadoop-cluster-{{ ds_nodash }}'},
    'pyspark_job': {
        'main_python_file_uri': f'{scripts_path}/trigger_hadoop.py',
        'args': [f'--input={job_args["input"]}',
                 f'--output={job_args["output"]}',
                 f'--mapper={job_args["mapper"]}',
                 f'--reducer={job_args["reducer"]}',
                 f'--files={scripts_path}/{job_args["mapper"]},{scripts_path}/{job_args["reducer"]}'
                 ]
    }
}

CLUSTER_CONFIG = {
    'master_config': {'num_instances': 1, 'machine_type_uri': 'n1-standard-2'},
    'worker_config': {'num_instances': 2, 'machine_type_uri': 'n1-standard-2'},
}

yesterday = datetime.datetime.combine(
    datetime.datetime.today() - datetime.timedelta(1), datetime.datetime.min.time()
)

default_dag_args = {
    'start_date': yesterday,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': datetime.timedelta(minutes=5),
    'project_id': '{{ var.value.gcp_project }}',
    'region': '{{ var.value.gce_region }}',
}


with models.DAG(
    'composer_hadoop',
    schedule_interval=datetime.timedelta(days=1),
    default_args=default_dag_args,
) as dag:

    create_dataproc_cluster = dataproc.DataprocCreateClusterOperator(
        task_id='create_dataproc_cluster',
        cluster_name='composer-hadoop-cluster-{{ ds_nodash }}',
        cluster_config=CLUSTER_CONFIG,
        region='{{ var.value.gce_region }}',
    )

    run_dataproc_hadoop = dataproc.DataprocSubmitJobOperator(
        task_id='run_dataproc_hadoop', job=PYSPARK_JOB
    )

    delete_dataproc_cluster = dataproc.DataprocDeleteClusterOperator(
        task_id='delete_dataproc_cluster',
        cluster_name='composer-hadoop-cluster-{{ ds_nodash }}',
        region='{{ var.value.gce_region }}',
        trigger_rule=trigger_rule.TriggerRule.ALL_DONE,
    )

    create_dataproc_cluster >> run_dataproc_hadoop >> delete_dataproc_cluster