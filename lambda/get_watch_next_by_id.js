// MyTEDx Rewind - Lambda Function completa
// Scopo: dato l'ID di un talk, restituisce i talk suggeriti ordinati per punteggio

const { MongoClient } = require("mongodb");

// Inserisci il tuo URI MongoDB Atlas
const uri = "mongodb+srv://<utente>:<password>@cluster.mongodb.net/?retryWrites=true&w=majority";
const client = new MongoClient(uri);

exports.handler = async (event) => {
    console.log("⏳ Richiesta ricevuta:", event);

    try {
        // 1. Validazione dell'input
        if (!event.body) {
            return erroreClient("Nessun corpo nella richiesta.");
        }

        const body = JSON.parse(event.body);
        if (!body.id || typeof body.id !== "string") {
            return erroreClient("ID non valido. Deve essere una stringa.");
        }

        const talkId = body.id.trim();

        // 2. Connessione al DB
        await client.connect();
        const db = client.db("tedx");
        const talks = db.collection("talks");

        // 3. Recupero del talk principale
        const mainTalk = await talks.findOne({ _id: talkId });
        if (!mainTalk) {
            return erroreClient("Talk non trovato.");
        }

        // 4. Recupero dei talk suggeriti (related_talks)
        const relatedIds = (mainTalk.related_talks || []).map(r => r.id);

        if (!relatedIds.length) {
            return {
                statusCode: 200,
                body: JSON.stringify({
                    talk_corrente: mainTalk.title,
                    messaggio: "Nessun talk suggerito trovato.",
                    suggeriti: []
                }),
            };
        }

        // 5. Query multipla per ottenere info dettagliate dei related
        const relatedTalksRaw = await talks.find({ _id: { $in: relatedIds } }).toArray();

        // 6. Costruzione lista suggerimenti con punteggio finale
        const suggeriti = relatedTalksRaw.map(t => {
            const baseScore = t.score || 50;
            const bonus = t.tags?.includes("innovation") ? 10 : 0;
            const finalScore = baseScore + bonus;

            return {
                id: t._id,
                title: t.title,
                tags: t.tags || [],
                score: finalScore
            };
        });

        // 7. Ordinamento per score decrescente
        suggeriti.sort((a, b) => b.score - a.score);

        // 8. Risposta finale
        return {
            statusCode: 200,
            body: JSON.stringify({
                talk_corrente: mainTalk.title,
                suggeriti: suggeriti
            }),
        };

    } catch (err) {
        console.error("❌ Errore interno:", err);
        return {
            statusCode: 500,
            body: JSON.stringify({ errore: "Errore interno del server" }),
        };
    } finally {
        await client.close();
        console.log("✅ Connessione chiusa.");
    }
};

// Funzione per errori lato client (400)
function erroreClient(messaggio) {
    return {
        statusCode: 400,
        body: JSON.stringify({ errore: messaggio }),
    };
}
