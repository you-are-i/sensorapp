FROM python:3.7-slim

RUN apt-get -y update && apt-get -y install gcc wget unzip

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

WORKDIR /

COPY hello.py /
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PORT 5000

EXPOSE 5000

ENTRYPOINT ["python3", "-X", "utf8", "-u", "hello.py"]
