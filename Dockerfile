FROM python:3.10-slim as base
# Set up common environment.
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    SPAERO_COMPILER_API_PORT=54535


# Build stage.
FROM base as builder

ENV VENV_NAME=venv

# Install PDM.
RUN pip install -U pip setuptools wheel
RUN pip install "pdm==2.5.6"

# Copy PDM files for the project.
COPY pyproject.toml pdm.lock README.md /project/

# Install dependencies in a venv before the project.
WORKDIR /project
RUN pdm config check_update false \
    && pdm venv create --with-pip --name $VENV_NAME python3  \
    && pdm use --venv=$VENV_NAME

FROM builder as prod-build

RUN pdm install --skip :all --prod --no-self --no-lock --no-editable
# Install the project.
COPY src/ /project/src
RUN pdm install --skip :all --prod --no-lock --no-editable

# Move PDM venv to a standard location to grab for the final image.
RUN sh -c "mv $(pdm venv --path $VENV_NAME) /project/venv"


# Final image.
FROM builder AS dev

RUN pdm install --skip :all --dev --no-self --no-lock --no-editable
COPY src/ /project/src
RUN pdm install --skip :all --dev --no-lock --no-editable
CMD [ "pdm", "all" ]


FROM base
RUN apt-get update \
	&& apt-get install --no-install-recommends -y \
	libblas3 \
	liblapack3 \
	libumfpack5 \
	&& rm -rf /var/lib/apt/lists/*

# Retrieve packages from build stage.
COPY --from=prod-build /project/venv /project/venv

CMD [ "python3", "-c", "print('hello world')" ]
