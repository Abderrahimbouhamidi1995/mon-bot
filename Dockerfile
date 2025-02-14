FROM rasa/rasa:latest-full

WORKDIR /app

COPY config.yml /app/config.yml
COPY domain.yml /app/domain.yml
COPY data/nlu.yml /app/data/nlu.yml
COPY data/rules.yml /app/data/rules.yml
EXPOSE 5005

RUN rasa train


CMD ["rasa", "run", "--model", "/app/models", "--enable-api", "--cors", "*", "--debug"]