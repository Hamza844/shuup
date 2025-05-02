FROM python:3.9-slim

# 1. Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev libffi-dev \
    libjpeg-dev zlib1g-dev \
    libpangocairo-1.0-0 \
    python3-dev python3-pil \
    && rm -rf /var/lib/apt/lists/*

# 2. Set work directory
WORKDIR /app

# 3. Copy application code and requirements
COPY . .

# 4. Install Python dependencies
RUN pip install --no-cache-dir -r requirements-tests.txt && \
    pip install --no-cache-dir -e . && \
    python -c "import django; print(f'Django {django.__version__} installed successfully')"

# 5. Verify critical packages are available
RUN python -c "\
    import django; \
    import shuup; \
    print(f'Django {django.__version__} and Shuup {shuup.__version__} installed successfully')"

# 6. Set environment variables for Django
ENV DJANGO_SETTINGS_MODULE=shuup_workbench.settings
ENV PYTHONUNBUFFERED=1

# 7. Initialize DB and create admin
RUN python -m shuup_workbench migrate && \
    python -m shuup_workbench shuup_init && \
    echo "\
from django.contrib.auth import get_user_model; \
User = get_user_model(); \
try: \
    User.objects.create_superuser('admin', 'admin@admin.com', 'admin'); \
except Exception as e: \
    print(f'User creation error: {e}')" | python -m shuup_workbench shell

# 8. Expose port and start server
EXPOSE 8000
CMD ["python", "-m", "shuup_workbench", "runserver", "0.0.0.0:8000"]
