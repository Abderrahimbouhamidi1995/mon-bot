# ---- Base Stage ----
    FROM rasa/rasa:latest-full AS base
    WORKDIR /app
    
    # Copier les fichiers essentiels de configuration et les données
    COPY config.yml domain.yml /app/
    COPY data/nlu.yml data/rules.yml /app/data/
    
    # Copier également les tests et le fichier CSV de test
    COPY tests/ /app/tests/
    COPY requirements.txt /app/
    COPY .git /app/.git
    
    # Installer Git et les certificats CA, ainsi que les dépendances supplémentaires
    USER root
    RUN apt-get update && apt-get install -y git ca-certificates && update-ca-certificates
    RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt
    
# ---- Test Stage ----
    FROM base AS test
    EXPOSE 5005
    ENTRYPOINT []
    CMD ["bash", "-c", "echo 'Starting training...'; rasa train && echo 'Launching Rasa server on port 5005...' && rasa run --port 5005 --enable-api --cors '*' --debug & PID=$!; echo 'Waiting for Rasa server to be ready...' && until curl -s http://localhost:5005/status; do sleep 5; done; echo 'Server is up, running tests...' && robot tests/utterances_tests.robot; echo 'Tests finished, stopping Rasa server...' && kill $PID && if grep -q 'Incorrect' /app/tests/test_results.csv; then echo 'Test results contain Incorrect. Reverting last commit...'; git config --global --add safe.directory /app && git config --global user.email \"a.bouhamidi@outlook.com\" && git config --global user.name \"Abderrahimbouhamidi1995\" && git reset --hard HEAD~1 && git push origin HEAD --force; exit 1; else echo 'All tests passed.'; exit 0; fi"]
    # ---- Production Stage ----
    FROM base AS prod
    EXPOSE 5005
    CMD ["rasa", "run", "--port", "5005", "--model", "/app/models", "--enable-api", "--cors", "*", "--debug"]    