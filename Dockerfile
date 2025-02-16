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
FROM base AS test
ENTRYPOINT []
EXPOSE 5005
CMD ["bash", "-c", "\
    echo 'Starting training...' && \
    rasa train && \
    echo 'Launching Rasa server...' && \
    rasa run --port 5005 --enable-api --cors '*' --debug & \
    PID=$! && \
    echo 'Waiting for Rasa server to be ready...' && \
    until curl -s http://localhost:5005/status; do sleep 5; done && \
    echo 'Server is up, running tests...' && \
    robot tests/utterances_tests.robot && \
    echo 'Tests finished, stopping Rasa server...' && \
    kill $PID && \
    if grep -q 'Incorrect' /app/tests/test_results.csv; then \
        echo 'Test results contain Incorrect. Reverting last commit...'; \
        git revert HEAD --no-edit; exit 1; \
    else \
        echo 'All tests passed.'; exit 0; \
    fi"]
    
# ---- Production Stage ----
FROM base AS prod
# On suppose que le modèle a été entraîné par le stage test et se trouve dans /app/models
CMD ["rasa", "run", "--model", "/app/models", "--enable-api", "--cors", "*", "--debug"]    