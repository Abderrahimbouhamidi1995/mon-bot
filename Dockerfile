# Utiliser l'image Rasa complète
FROM rasa/rasa:latest-full

# Définir le répertoire de travail
WORKDIR /app

# Copier le projet
COPY . .

# Exposer le port 5005 pour les requêtes API Rasa
EXPOSE 5005

# Lancer le bot en mode serveur API
CMD ["run", "-m", "models", "--enable-api", "--cors", "*", "--debug"]