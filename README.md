# MyTEDx Rewind – Progetto Cloud & Mobile

**MyTEDx Rewind** è una piattaforma pensata per riscoprire TEDx Talk dimenticati ma di grande valore, utilizzando strumenti cloud e tecniche di analisi semantica. Il sistema suggerisce talk correlati attraverso un’infrastruttura serverless e un’app Flutter dedicata.

---

## Obiettivi del progetto

- Suggerire TEDx Talk poco visualizzati ma con alto valore semantico
- Offrire un’esperienza personalizzata agli utenti tramite suggerimenti intelligenti
- Costruire un’infrastruttura scalabile, serverless e accessibile da mobile

---

## Architettura Tecnologica

- **Amazon S3** – Archiviazione dei dataset CSV
- **AWS Glue (PySpark)** – ETL dei dati e calcolo `related_talks`
- **Amazon Comprehend** – Analisi semantica e sentiment
- **MongoDB Atlas** – Database NoSQL finale
- **AWS Lambda + API Gateway** – Backend serverless per le API
- **Amazon OpenSearch** – Ricerca semantica
- **Flutter** – App mobile cross-platform
- **GitHub + CodePipeline** – CI/CD

---

## Funzionalità chiave

- Navigazione tra video suggeriti dopo ogni visione
- Calcolo dinamico del punteggio dei talk (basato su parole chiave e sentiment)
- Evidenziazione delle frasi chiave tramite analisi NLP
- Aggiornamento del punteggio tramite Lambda function `update_percentage`

---

## Dataset trattati

- `talks.csv`: metadati dei video (id, title, tag, ecc.)
- `watch_next.csv`: relazioni tra talk
- `transcripts.csv`: trascrizioni per analisi semantica

---

## Job PySpark – AWS Glue

- Join dei dataset
- Calcolo punteggio semantico
- Creazione campo `related_talks`
- Scrittura su MongoDB

Esempio schema output:

```json
{
  "_id": "123",
  "title": "Innovazione nella scuola",
  "related_talks": [
    { "id": "456", "title": "Educazione del futuro", "score": 84 }
  ],
  "keywords": ["education", "future"],
  "sentiment": "positive"
}
```

---

## Lambda Functions

### `get_watch_next_by_id.js`
Restituisce i talk suggeriti per un dato ID, ordinati per punteggio personalizzato.

### `update_percentage.js`
Aggiorna dinamicamente il punteggio `score` di un talk in base al feedback utente (con logica 80/20).

---

## Esempio di chiamata API

**Richiesta:**
```json
POST /get_watch_next
{ "id": "123" }
```

**Risposta:**
```json
{
  "talk_corrente": "Come costruire un futuro migliore",
  "suggeriti": [
    { "id": "456", "title": "Progettare il futuro", "score": 85 },
    { "id": "789", "title": "Insegnare l'innovazione", "score": 78 }
  ]
}
```

---

## Struttura del repository

```
/lambda/
  get_watch_next_by_id.js
  update_percentage.js

/glue/
  pyspark_job.py

/api_examples/
  response_example.json

/presentation/
  MyTEDx_Rewind_Presentation.pptx

README.md
```

---

