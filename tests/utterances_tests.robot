*** Settings ***
Library           RequestsLibrary
Library           OperatingSystem
Library           Collections
Library           String

*** Variables ***
${API_URL}        https://localhost/webhooks/rest/webhook
${SENDER}         test_user
${CSV_FILE}       ./tests/testdata.csv
${CSV_OUTPUT}     ./tests/test_results.csv

*** Test Cases ***
Lire et Tester Toutes les Utterances
    Create Session    rasa_session    ${API_URL}    headers={"Content-Type": "application/json"}
    ${data}=    Lire CSV    ${CSV_FILE}
    ${results}=    Create List
    FOR    ${row}    IN    @{data}
        ${question}=    Set Variable    ${row}[0]
        ${expected_response}=    Set Variable    ${row}[1]
        Log To Console    \nTEST: ${question} -> ${expected_response}
        ${status}=    Tester Utterance    ${question}    ${expected_response}
        ${result_row}=    Create List    ${question}    ${expected_response}    ${status}
        Append To List    ${results}    ${result_row}
    END
    Écrire Résultats CSV    ${CSV_OUTPUT}    ${results}

*** Keywords ***
Lire CSV
    [Arguments]    ${file_path}
    ${file_content}=    Get File    ${file_path}    encoding=utf-8
    ${lines}=    Evaluate    list(csv.reader("""${file_content}""".splitlines(), delimiter=','))    modules=csv
    [Return]    ${lines}[1:]    # Ignore l'en-tête

Tester Utterance
    [Arguments]    ${question}    ${expected_response}
    ${response}=    Envoyer Message Au Chatbot    ${question}
    Log To Console    \nRAW API RESPONSE: ${response}
    ${length}=    Get Length    ${response}
    Run Keyword If    ${length} == 0    Fail    "Erreur : La réponse du bot est vide."
    ${first}=    Get From List    ${response}    0
    ${has_text}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${first}    text
    Run Keyword If    not ${has_text}    Fail    "Erreur : La réponse ne contient pas de clé 'text'."
    ${text}=    Get From Dictionary    ${first}    text
    Log To Console    RESPONSE: '${text}'
    # Nettoyer les chaînes en supprimant les espaces superflus et les retours à la ligne
    ${text_stripped}=    Strip String    ${text}
    ${expected_stripped}=    Strip String    ${expected_response}
    Log To Console    Cleaned RESPONSE: '${text_stripped}'
    Log To Console    Cleaned EXPECTED: '${expected_stripped}'
    ${status}=    Run Keyword And Return Status    Should Be Equal As Strings    ${text_stripped}    ${expected_stripped}
    ${result}=    Set Variable If    ${status} == True    Correct    Incorrect
    [Return]    ${result}

Envoyer Message Au Chatbot
    [Arguments]    ${message}
    ${data}=    Create Dictionary    sender=${SENDER}    message=${message}
    ${response}=   POST On Session    rasa_session    /    json=${data}
    Should Be Equal As Integers    ${response.status_code}    200    msg="Erreur : La requête API a échoué avec le code ${response.status_code}"
    ${json_resp}=  Convert To List    ${response.json()}
    Run Keyword If    ${json_resp} == []    Fail    "Erreur : Le bot n'a pas répondu à la requête."
    [Return]       ${json_resp}

Écrire Résultats CSV
    [Arguments]    ${file_path}    ${data}
    ${header}=    Create List    "question"    "expected_response"    "result"
    ${content}=    Create List    ${header}    @{data}
    ${csv_lines}=    Create List
    FOR    ${row}    IN    @{content}
        ${csv_line}=    Catenate    SEPARATOR=,    @{row}
        Append To List    ${csv_lines}    ${csv_line}
    END
    ${csv_text}=    Catenate    SEPARATOR=\n    @{csv_lines}
    Create File    ${file_path}    ${csv_text}
    Log To Console    ✅ Résultats enregistrés dans ${file_path}