# Utiliser l'image Rasa complète
FROM rasa/rasa:latest-full

# Définir le répertoire de travail
WORKDIR /app

# Copier uniquement les fichiers nécessaires
COPY config.yml /app/config.yml
COPY domain.yml /app/domain.yml
COPY data/ /app/data/
COPY projects/ /app/projects/

# Exécuter l'entraînement du modèle
RUN rasa train

# Exposer le port 5005 pour l'API Rasa
EXPOSE 5005

# Lancer le bot avec le modèle entraîné
CMD ["rasa", "run", "--model", "/app/models", "--enable-api", "--cors", "*", "--debug"]