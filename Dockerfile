# Utiliser l'image Rasa complète
FROM rasa/rasa:latest-full

# Définir le répertoire de travail
WORKDIR /app

# Copier le projet
COPY . /app

COPY models/ /app/models/

RUN rasa train --fixed-model-name bot --domain domain.yml --data data --out models

# Lancer le bot en mode serveur API
CMD ["run", "-m", "models", "--enable-api", "--cors", "*", "--debug"]