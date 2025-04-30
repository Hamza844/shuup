# ───────────────────────────────────────────────────────────────────────────────
# 1. BUILDER STAGE
# ───────────────────────────────────────────────────────────────────────────────
FROM node:12.21.0-buster-slim AS builder

LABEL maintainer="Eero Ruohola <eero.ruohola@shuup.com>"

# Install system and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-dev python3-pip python3-venv python3-pil \
    build-essential libssl-dev libffi-dev \
    cargo rustc \
    libjpeg-dev zlib1g-dev \
    libpangocairo-1.0-0 \
    && pip3 install --upgrade pip setuptools wheel \
    && rm -rf /var/lib/apt/lists/*

# Set environment variable to avoid Rust build
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1

# Set work directory
WORKDIR /app

# Copy project files
COPY . .

# Build ARG for editable install
ARG EDITABLE=0

# Set up Python virtual environment and install dependencies
RUN python3 -m venv /opt/venv && . /opt/venv/bin/activate && \
    if [ "$EDITABLE" = "1" ]; then \
        pip install --no-cache-dir -r requirements-tests.txt && \
        pip install --no-cache-dir "jinja2<3.1" "markupsafe<2.1" "cryptography<3.4" && \
        python setup.py build_resources; \
    else \
        pip install --no-cache-dir shuup && \
        pip install --no-cache-dir "jinja2<3.1" "markupsafe<2.1" "cryptography<3.4"; \
    fi

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"
ENV DJANGO_SETTINGS_MODULE=shuup_workbench.settings

# Run database migrations and initialize Shuup
RUN python3 -m shuup_workbench migrate && \
    python3 -m shuup_workbench shuup_init

# Create default admin user (admin/admin)
RUN echo "\
from django.contrib.auth import get_user_model\n\
from django.db import IntegrityError\n\
try:\n\
    get_user_model().objects.create_superuser('admin', 'admin@admin.com', 'admin')\n\
except IntegrityError:\n\
    pass\n" | python3 -m shuup_workbench shell

# ───────────────────────────────────────────────────────────────────────────────
# 2. RUNTIME STAGE
# ───────────────────────────────────────────────────────────────────────────────
FROM python:3.9-slim

LABEL maintainer="Eero Ruohola <eero.ruohola@shuup.com>"

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpangocairo-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"
ENV DJANGO_SETTINGS_MODULE=shuup_workbench.settings
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Copy only necessary artifacts from the builder stage
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app /app

# Expose port
EXPOSE 8000

# Start Shuup application
CMD ["python3", "-m", "shuup_workbench", "runserver", "0.0.0.0:8000"]
