# ProgettoCloud
# MyTEDx Rewind – Progetto Cloud & Mobile

**MyTEDx Rewind** è un progetto sviluppato per riscoprire e valorizzare TEDx Talk dimenticati ma di grande qualità, offrendo un’esperienza utente moderna, personalizzata e accessibile da mobile. L'applicazione si basa su un'infrastruttura cloud completamente serverless e utilizza strumenti come AWS Lambda, Glue, MongoDB, OpenSearch e Flutter.

---

## Obiettivi del progetto

- Suggerire talk TEDx poco visualizzati ma rilevanti dal punto di vista contenutistico.
- Analizzare automaticamente i contenuti dei talk tramite Amazon Comprehend per identificare parole chiave e sentiment.
- Consentire all’utente di navigare facilmente tra i video suggeriti.
- Costruire un sistema che apprende le preferenze dell’utente nel tempo.

---

## Tecnologie utilizzate

- **AWS Lambda** – Funzioni serverless per esporre le API
- **Amazon Glue + PySpark** – Job ETL per unire dataset e generare suggerimenti
- **Amazon Comprehend** – Analisi semantica delle trascrizioni
- **Amazon S3** – Storage dei file CSV
- **MongoDB Atlas** – Database NoSQL per i talk elaborati
- **Amazon OpenSearch** – Ricerca semantica tra i contenuti
- **API Gateway** – REST API backend ↔ frontend
- **Flutter** – Frontend mobile multipiattaforma
- **GitHub + CodePipeline** – Versionamento e CI/CD

---

## Struttura del repository
/lambda/
get_watch_next_by_id.js      # Funzione Lambda per suggerimenti video

/glue/
pyspark_job.py               # Job PySpark per costruzione campi related_talks

/api_examples/
response_example.json        # Esempio JSON di risposta API

README.md                      # Questo file
---

## Come funziona

1. I dati TEDx (`talks.csv`, `watch_next.csv`, `transcripts.csv`) vengono caricati su Amazon S3.
2. Il job PySpark su AWS Glue unisce e arricchisce i dati, analizza i contenuti con Amazon Comprehend, e calcola un punteggio.
3. Il dataset elaborato viene salvato su MongoDB Atlas, con ogni talk arricchito da un array `related_talks`.
4. Le API Lambda permettono di:
   - Recuperare talk correlati (`get_watch_next_by_id`)
   - Mostrare highlights significativi con sentiment
   - Aggiornare le preferenze dell’utente
5. L’app Flutter accede ai dati tramite API Gateway, offrendo una UX moderna e interattiva.
