FROM python:latest

ARG DIRNAME
ARG PYVENV_LOCATION

COPY . "${DIRNAME}"
WORKDIR "${DIRNAME}"
EXPOSE 443
EXPOSE 80


RUN /usr/bin/env python3 -m venv "${PYVENV_LOCATION}"
RUN "${PYVENV_LOCATION}/bin/python" -m pip install -r requirements.txt
RUN chmod +x shell/run.sh