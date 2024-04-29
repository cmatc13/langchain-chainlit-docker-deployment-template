# The builder image, used to build the virtual environment
FROM python:3.11-slim-buster as builder

# Install system dependencies
RUN apt-get update -y && apt-get install -y git libsqlite3-dev wget xvfb unzip gnupg jq

# Fetch the latest version numbers and URLs for Chrome and ChromeDriver
RUN wget -qO /tmp/versions.json https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json

RUN CHROME_URL=$(jq -r '.channels.Stable.downloads.chrome[] | select(.platform=="linux64") | .url' /tmp/versions.json) && \
    wget -q --continue -O /tmp/chrome-linux64.zip $CHROME_URL && \
    unzip /tmp/chrome-linux64.zip -d /opt/chrome

RUN chmod +x /opt/chrome/chrome-linux64/chrome

RUN CHROMEDRIVER_URL=$(jq -r '.channels.Stable.downloads.chromedriver[] | select(.platform=="linux64") | .url' /tmp/versions.json) && \
    wget -q --continue -O /tmp/chromedriver-linux64.zip $CHROMEDRIVER_URL && \
    unzip /tmp/chromedriver-linux64.zip -d /opt/chromedriver && \
    chmod +x /opt/chromedriver/chromedriver-linux64/chromedriver

# Set up Chromedriver Environment variables
ENV CHROMEDRIVER_DIR /opt/chromedriver
ENV PATH $CHROMEDRIVER_DIR:$PATH

# Clean up
RUN rm /tmp/chrome-linux64.zip /tmp/chromedriver-linux64.zip /tmp/versions.json

# Install Poetry
RUN pip install poetry==1.8.2

# Set Poetry environment variables
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# Expose ports and set working directory
EXPOSE 8000
WORKDIR /app

# Copy Poetry files and install dependencies
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-root --no-dev --no-interaction --no-ansi --no-plugins \
    && rm -rf $POETRY_CACHE_DIR

# Copy the demo_app directory, including main.py
COPY ./demo_app ./demo_app

# Copy the ChromeDriver binary to /usr/local/bin/
RUN cp $CHROMEDRIVER_DIR/chromedriver /usr/local/bin/

# The runtime image, used to just run the code provided its virtual environment
FROM python:3.11-slim-buster as runtime

# Set environment variables and copy files from builder stage
ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"
COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}
COPY --from=builder /app/demo_app /app/demo_app
COPY ./.chainlit ./.chainlit
COPY chainlit.md ./
# Copy CHROMEDRIVER_DIR from the builder stage to the runtime stage
COPY --from=builder /tmp/chromedriver_dir.txt /tmp/chromedriver_dir.txt

WORKDIR /app

# Define default command to run the application
CMD ["bash", "-c", "chainlit run demo_app/main.py"]
