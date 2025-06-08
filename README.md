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
- **MongoDB Atlas** – Database NoSQL finale
- **AWS Lambda + API Gateway** – Backend serverless per le API
- **Flutter** – App mobile cross-platform
- **GitHub** – CI/CD

---

## Funzionalità chiave

- Navigazione tra talk suggeriti dopo ogni visione
- Calcolo dinamico del punteggio dei talk (basato su parole chiave e sentiment)
- Aggiornamento del punteggio tramite Lambda function `update_percentage`

---

## Dataset trattati

- `final_list.csv`: metadati dei video (id, title, tag, ecc.)
- `related_videos.csv`: relazioni tra talk
- `details.csv`: trascrizioni per analisi semantica
- `tags.csv`

---

## Job PySpark – AWS Glue

1. Caricamento dati da S3

Legge 4 file CSV da S3: final_list.csv, details.csv, tags.csv, e related_videos.csv
Tutti i file contengono informazioni sui talk TEDx

2. Elaborazione e join dei dataset

Dataset principale: parte da final_list.csv
Dettagli: fa join con details.csv per aggiungere descrizioni, durata, presenter, data di pubblicazione
Tags: aggrega i tag per ogni video raggruppandoli in un array
Video correlati: elabora le relazioni tra video creando una struttura con score semantico

3. Processamento video correlati
Il job crea un sistema di raccomandazioni:

Calcola uno score semantico basato sul numero di visualizzazioni (normalizzato)
Raggruppa i video correlati per ogni talk principale
Li ordina per score e mantiene solo i top 10
Crea una struttura con: ID, score, titolo, presenter

4. Dataset finale
Produce un documento per ogni talk TEDx con:

Tutti i metadati originali
Dettagli estesi (descrizione, durata, etc.)
Array di tag
Array di talk correlati con score di rilevanza

5. Salvataggio in MongoDB

Converte il dataset in formato compatibile MongoDB
Salva nella collection tedx_data del database unibg_tedx_2025
Usa l'ID del video come _id di MongoDB

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

- Trova un talk specifico usando identificatori flessibili
- Suggerisce contenuti correlati basati su score pre-calcolati
- Gestisce inconsistenze negli ID tra diversi dataset
- Fornisce un'API robusta per il frontend di un'applicazione TEDx

### `update_percentage.js`

- Apprendimento continuo: I talk migliorano/peggiorano i loro score basandosi sul feedback reale
- Effetto rete: Il feedback su un talk influenza anche i talk correlati
- Stabilità: La regola 80/20 evita oscillazioni brusche degli score
- Tracciabilità: Mantiene storico completo per analisi e debug

### `add_favorites`

- Salvare talk interessanti per dopo
- Creare liste personalizzate
- Avere accesso rapido ai contenuti preferiti

### `remove_favorites`

- Rimuovere talk che non interessano più
- Gestire dinamicamente la propria lista preferiti
- Avere controllo completo sui contenuti salvati

### `get_favorites`

- Visualizzazione di tutti i talk salvati
- Accesso rapido ai contenuti preferiti
- Esperienza consistente anche se alcuni talk vengono modificati/cancellati

### `check_favorite`

- Mostrare icona "cuore pieno/vuoto" nei talk
- Aggiornare UI in tempo reale
- Evitare tentativi di aggiunta duplicata

Pattern di utilizzo tipico:

User carica pagina talk → check_favorite
User clicca "aggiungi" → add_favorites
User clicca "rimuovi" → remove_favorites
User visualizza lista → get_favorites


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
  get_watch_next_by_id/
  update_percentage/
  get_all/
  add_favorites/
  remove_favorites/
  check_favorites/
  get_favorites/

Ogni cartella funzione lambda contiene la corrispettiva funzione handler.js, db.js, Talk.js, Favorites.js (per le funzioni favorites)
 e la environmental variable per connettersi al database.

/glue/
  pyspark_job.py

/presentation/
  MyTEDx_Rewind_Presentation.pptx

README.md
```

---

