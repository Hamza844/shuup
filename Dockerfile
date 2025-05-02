# ───────────────────────────────────────────────────────────────────────────────
# 1. BUILDER STAGE
# ───────────────────────────────────────────────────────────────────────────────
FROM python:3.9-slim AS builder

LABEL maintainer="Eero Ruohola <eero.ruohola@shuup.com>"

# Install system and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libssl-dev libffi-dev \
    cargo rustc \
    libjpeg-dev zlib1g-dev \
    libpangocairo-1.0-0 \
    python3-dev python3-pil \
    && pip install --upgrade pip setuptools wheel \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements-tests.txt .

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"
ENV VIRTUAL_ENV="/opt/venv"
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1

# Create and activate virtual environment
RUN python -m venv /opt/venv

# Install Python dependencies
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir -r requirements-tests.txt && \
    pip install --no-cache-dir shuup && \
    pip install --no-cache-dir "jinja2<3.1" "markupsafe<2.1" "cryptography<3.4"

# Clean up build dependencies
RUN apt-get purge -y cargo rustc && \
    apt-get autoremove -y && \
    rm -rf /root/.cargo /usr/lib/rustlib /root/.cache/pip

# Copy the rest of the application
COPY . .

# Set Django settings
ENV DJANGO_SETTINGS_MODULE=shuup_workbench.settings

# Run database migrations and initialize Shuup
RUN . /opt/venv/bin/activate && \
    python -m shuup_workbench migrate && \
    python -m shuup_workbench shuup_init

# Create default admin user (admin/admin)
RUN echo "\
from django.contrib.auth import get_user_model\n\
from django.db import IntegrityError\n\
try:\n\
    get_user_model().objects.create_superuser('admin', 'admin@admin.com', 'admin')\n\
except IntegrityError:\n\
    pass\n" | /opt/venv/bin/python -m shuup_workbench shell

# ───────────────────────────────────────────────────────────────────────────────
# 2. RUNTIME STAGE
# ───────────────────────────────────────────────────────────────────────────────
FROM python:3.9-slim

LABEL maintainer="Eero Ruohola <eero.ruohola@shuup.com>"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpangocairo-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV DJANGO_SETTINGS_MODULE=shuup_workbench.settings
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Copy virtual environment and application
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app /app

# Verify Django is installed (for debugging)
RUN . /opt/venv/bin/activate && python -c "import django; print(django.__version__)"

# Expose port
EXPOSE 8000

# Start Shuup application
CMD ["/opt/venv/bin/python", "-m", "shuup_workbench", "runserver", "0.0.0.0:8000"]