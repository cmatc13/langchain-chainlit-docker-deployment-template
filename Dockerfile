# Start from the base Python image
FROM python:3.11-slim-buster as builder

# Install system dependencies
RUN apt-get update && apt-get install -y wget unzip jq

# Fetch the latest version numbers and URLs for Chrome and ChromeDriver
RUN wget -qO /tmp/versions.json https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json

# Install Chrome and Chromedriver
RUN CHROME_URL=$(jq -r '.channels.Stable.downloads.chrome[] | select(.platform=="linux64") | .url' /tmp/versions.json) && \
    wget -q --continue -O /tmp/chrome-linux64.zip $CHROME_URL && \
    unzip /tmp/chrome-linux64.zip -d /opt/chrome && \
    chmod +x /opt/chrome/chrome-linux64/chrome

RUN CHROMEDRIVER_URL=$(jq -r '.channels.Stable.downloads.chromedriver[] | select(.platform=="linux64") | .url' /tmp/versions.json) && \
    wget -q --continue -O /tmp/chromedriver-linux64.zip $CHROMEDRIVER_URL && \
    unzip /tmp/chromedriver-linux64.zip -d /opt/chromedriver && \
    chmod +x /opt/chromedriver/chromedriver-linux64/chromedriver

# Set up Chromedriver Environment variables
ENV PATH "/opt/chromedriver:$PATH"

# Clean up
RUN rm /tmp/chrome-linux64.zip /tmp/chromedriver-linux64.zip /tmp/versions.json

# Create a virtual environment and activate it
RUN python -m venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Install Poetry and other Python dependencies
RUN apt-get install -y python3-pip && \
    pip install poetry==1.8.2

# Copy and install dependencies using Poetry
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-root --no-dev --no-interaction --no-ansi --no-plugins \
    && rm -rf $POETRY_CACHE_DIR

# Install additional Python packages from requirements.txt
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Expose ports and set working directory
EXPOSE 8000
WORKDIR /app

# Copy the demo_app directory, including main.py
COPY ./demo_app ./demo_app

# The runtime image, used to just run the code provided its virtual environment
FROM python:3.11-slim-buster as runtime

# Set environment variables and copy files from builder stage
ENV VIRTUAL_ENV="/app/.venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
COPY --from=builder $VIRTUAL_ENV $VIRTUAL_ENV
COPY --from=builder /app/demo_app /app/demo_app
COPY ./.chainlit ./.chainlit
COPY chainlit.md ./

# Copy Chrome and Chromedriver from the builder stage to the runtime stage
COPY --from=builder /opt/chrome /opt/chrome
COPY --from=builder /opt/chromedriver /opt/chromedriver

# Ensure the Chromedriver binary has executable permissions
RUN chmod +x /opt/chromedriver/chromedriver-linux64/chromedriver
RUN chmod +x /opt/chrome/chrome-linux64/chrome

WORKDIR /app

# Define default command to run the application
CMD ["bash", "-c", "chainlit run demo_app/main.py"]
