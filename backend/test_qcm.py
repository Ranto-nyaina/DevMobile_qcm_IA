import requests

url = "http://127.0.0.1:8000/api/qcm/question-ouverte/corriger/"

data = {
    "question_id": 1,
    "reponse_etudiant": "Le Big Data correspond à de grandes quantités de données qui doivent être traitées avec des technologies adaptées."
}

response = requests.post(url, json=data)

print("Code :", response.status_code)
print(response.json())