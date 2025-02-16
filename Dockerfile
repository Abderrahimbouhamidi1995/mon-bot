# ---- Base Stage ----
FROM rasa/rasa:latest-full AS base
WORKDIR /app

# Copier les fichiers essentiels de configuration et les données
COPY config.yml domain.yml /app/
COPY data/nlu.yml data/rules.yml /app/data/

# Copier également les tests et le fichier CSV de test
COPY tests/ /app/tests/
COPY requirements.txt /app/

# Installer les dépendances supplémentaires
USER root
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# ---- Test Stage ----
# ---- Test Stage ----
FROM base AS test
ENTRYPOINT []
CMD ["bash", "-c", "rasa train && rasa run --enable-api --cors '*' --debug & sleep 20 && robot tests/utterances_tests.robot"]
    
# ---- Production Stage ----
FROM base AS prod
# On suppose que le modèle a été entraîné par le stage test et se trouve dans /app/models
CMD ["rasa", "run", "--model", "/app/models", "--enable-api", "--cors", "*", "--debug"]    