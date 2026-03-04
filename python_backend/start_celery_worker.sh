#!/bin/bash
# Start Celery worker for processing background tasks

# Navigate to the python_backend directory
cd "$(dirname "$0")"

# Start Celery worker with beat scheduler
celery -A app.celery_app worker --beat --loglevel=info
