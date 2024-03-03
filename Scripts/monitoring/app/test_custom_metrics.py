from flask import Response, Flask
from prometheus_client import generate_latest, Gauge
import random

app = Flask(__name__)
CUSTOM_METRIC = Gauge('python_custom_metric', 'test python custom metric')

@app.route("/metrics")
def requests_count():
    random_value = random.randint(1, 100)
    CUSTOM_METRIC.set(random_value)
    return Response(generate_latest(), mimetype="text/plain")

if __name__ == "__main__":
    app.run(host='0.0.0.0',port=8082)
