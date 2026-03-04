#!/bin/bash
# Start Celery beat scheduler separately (if running worker and beat separately)

# Navigate to the python_backend directory
cd "$(dirname "$0")"

# Start Celery beat scheduler
celery -A app.celery_app beat --loglevel=info
