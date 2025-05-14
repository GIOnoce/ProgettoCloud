// Lambda Function: update_percentage.js
// Scopo: aggiorna la percentuale di gradimento di un TEDx Talk in MongoDB

const { MongoClient } = require("mongodb");

// URI MongoDB (da sostituire con i tuoi dati reali)
const uri = "mongodb+srv://<utente>:<password>@cluster.mongodb.net/?retryWrites=true&w=majority";
const client = new MongoClient(uri);

exports.handler = async (event) => {
    console.log("📥 Richiesta ricevuta:", event);

    try {
        // 1. Validazione input
        if (!event.body) return erroreClient("Richiesta vuota");

        const body = JSON.parse(event.body);
        const { id, nuovo_valore } = body;

        if (!id || typeof id !== "string") {
            return erroreClient("ID non valido o mancante");
        }

        const valoreNuovo = parseInt(nuovo_valore);
        if (isNaN(valoreNuovo) || valoreNuovo < 0 || valoreNuovo > 100) {
            return erroreClient("Il valore deve essere un numero tra 0 e 100");
        }

        // 2. Connessione al DB
        await client.connect();
        const db = client.db("tedx");
        const talks = db.collection("talks");

        // 3. Recupero del talk
        const talk = await talks.findOne({ _id: id });

        if (!talk) {
            return erroreClient("Talk non trovato");
        }

        const vecchiaPercentuale = talk.score || 50;

        // 4. Calcolo nuova percentuale (80% vecchio + 20% nuovo)
        const nuovaPercentuale = Math.round((vecchiaPercentuale * 0.8) + (valoreNuovo * 0.2));

        // 5. Aggiornamento nel DB
        await talks.updateOne(
            { _id: id },
            { $set: { score: nuovaPercentuale } }
        );

        console.log(`✅ Percentuale aggiornata per il talk ${id}: ${vecchiaPercentuale} → ${nuovaPercentuale}`);

        return {
            statusCode: 200,
            body: JSON.stringify({
                id: id,
                vecchio: vecchiaPercentuale,
                nuovo: nuovaPercentuale,
                messaggio: "Aggiornamento completato con successo"
            })
        };

    } catch (err) {
        console.error("❌ Errore interno:", err);
        return {
            statusCode: 500,
            body: JSON.stringify({ errore: "Errore interno del server" }),
        };
    } finally {
        await client.close();
    }
};

// Funzione per errori client
function erroreClient(messaggio) {
    return {
        statusCode: 400,
        body: JSON.stringify({ errore: messaggio }),
    };
}
