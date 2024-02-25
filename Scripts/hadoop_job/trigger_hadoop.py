import subprocess
import os
import argparse

parser = argparse.ArgumentParser(description='Run Hadoop Streaming job.')
parser.add_argument('--input', help='Input path', required=True)
parser.add_argument('--output', help='Output path', required=True)
parser.add_argument('--mapper', help='Mapper script path', required=True)
parser.add_argument('--reducer', help='Reducer script path', required=True)
parser.add_argument('--files', help='files path', required=True)
args = parser.parse_args()

hadoop_command = [
    "mapred", "streaming",
    "-files", args.files,
    "-input", args.input,
    "-output", args.output,
    "-mapper", f"python3 {args.mapper}",
    "-reducer", f"python3 {args.reducer}"
]
try:
    subprocess.run(hadoop_command, check=True)
    print("Hadoop job done")
except subprocess.CalledProcessError as e:
    print("Hadoop job fail: ", e)
