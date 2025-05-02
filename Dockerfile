# ───────────────────────────────────────────────────────────────────────────────
# 1. BUILDER STAGE
# ───────────────────────────────────────────────────────────────────────────────
FROM python:3.9-slim AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev libffi-dev \
    libjpeg-dev zlib1g-dev \
    libpangocairo-1.0-0 \
    python3-dev python3-pil \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
COPY requirements-tests.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements-tests.txt && \
    pip install --no-cache-dir "Django>=3.2,<4.0" && \  # Explicit Django install
    pip install --no-cache-dir -e .

# Copy the rest of the application
COPY . .

# Initialize Shuup
RUN python -m shuup_workbench migrate && \
    python -m shuup_workbench shuup_init

# Create admin user
RUN echo "from django.contrib.auth import get_user_model; \
    User = get_user_model(); \
    try: User.objects.create_superuser('admin', 'admin@admin.com', 'admin'); \
    except: pass" | python -m shuup_workbench shell

# ───────────────────────────────────────────────────────────────────────────────
# 2. RUNTIME STAGE
# ───────────────────────────────────────────────────────────────────────────────
FROM python:3.9-slim

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpangocairo-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy virtual environment and app
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app /app

# Environment variables
ENV PATH="/opt/venv/bin:$PATH"
ENV DJANGO_SETTINGS_MODULE=shuup_workbench.settings
ENV PYTHONUNBUFFERED=1

# Verification commands
RUN python -c "import django; print(f'Django {django.__version__} installed')" && \
    python -c "from django.conf import settings; print(f'Settings module: {settings.SETTINGS_MODULE}')"

EXPOSE 8000
CMD ["python", "-m", "shuup_workbench", "runserver", "0.0.0.0:8000"]