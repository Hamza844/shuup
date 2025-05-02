# ───────────────────────────────────────────────────────────────────────────────
# SINGLE STAGE BUILD (for now to eliminate variables)
# ───────────────────────────────────────────────────────────────────────────────
FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev libffi-dev \
    libjpeg-dev zlib1g-dev \
    libpangocairo-1.0-0 \
    python3-dev python3-pil \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for better caching
COPY requirements-tests.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements-tests.txt && \
    pip install --no-cache-dir "Django>=3.2,<4.0" && \
    pip install --no-cache-dir -e .

# Copy the rest of the application
COPY . .

# Verify Django installation
RUN python -c "import django; print(f'Django {django.__version__} installed successfully')"

# Initialize Shuup
RUN python -m shuup_workbench migrate && \
    python -m shuup_workbench shuup_init

# Create admin user
RUN echo "from django.contrib.auth import get_user_model; \
    User = get_user_model(); \
    try: User.objects.create_superuser('admin', 'admin@admin.com', 'admin'); \
    except: pass" | python -m shuup_workbench shell

# Environment variables
ENV DJANGO_SETTINGS_MODULE=shuup_workbench.settings
ENV PYTHONUNBUFFERED=1

EXPOSE 8000
CMD ["python", "-m", "shuup_workbench", "runserver", "0.0.0.0:8000"]