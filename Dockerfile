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

# Copy project files
COPY . .

# Build ARG for editable install
ARG EDITABLE=0

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"
ENV DJANGO_SETTINGS_MODULE=shuup_workbench.settings
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1

# Set up Python virtual environment and install dependencies
RUN python -m venv /opt/venv && . /opt/venv/bin/activate && \
    if [ "$EDITABLE" = "1" ]; then \
        pip install --no-cache-dir -r requirements-tests.txt && \
        pip install --no-cache-dir "jinja2<3.1" "markupsafe<2.1" "cryptography<3.4" && \
        python setup.py build_resources; \
    else \
        pip install --no-cache-dir shuup && \
        pip install --no-cache-dir "jinja2<3.1" "markupsafe<2.1" "cryptography<3.4"; \
    fi && \
    apt-get purge -y cargo rustc && apt-get autoremove -y && rm -rf /root/.cargo /usr/lib/rustlib && \
    rm -rf /root/.cache/pip

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
    pass\n" | python -m shuup_workbench shell

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
CMD ["python", "-m", "shuup_workbench", "runserver", "0.0.0.0:8000"]
