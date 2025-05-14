// Lambda Function per ottenere i video "Watch Next" di un TEDx Talk
// Collegata a MongoDB Atlas
// Input: ID del talk
// Output: lista di talk suggeriti con titolo, id e punteggio

const { MongoClient } = require("mongodb");

// URI di connessione (da sostituire con i tuoi dati MongoDB Atlas)
const uri = "mongodb+srv://utente:password@cluster.mongodb.net/test?retryWrites=true&w=majority";
const client = new MongoClient(uri);

exports.handler = async (event) => {
    try {
        // Parsing del corpo della richiesta
        const body = JSON.parse(event.body);
        const talkId = body.id;

        if (!talkId) {
            return {
                statusCode: 400,
                body: JSON.stringify({ errore: "ID del talk mancante" }),
            };
        }

        // Connessione al database e alla collezione
        await client.connect();
        const database = client.db("tedx");
        const talks = database.collection("talks");

        // Cerchiamo il talk corrispondente all'ID
        const talk = await talks.findOne({ _id: talkId });

        if (!talk || !talk.related_talks) {
            return {
                statusCode: 404,
                body: JSON.stringify({ errore: "Talk non trovato o senza suggerimenti" }),
            };
        }

        // Restituiamo l'elenco dei talk suggeriti
        return {
            statusCode: 200,
            body: JSON.stringify({
                talk_corrente: talk.title,
                suggeriti: talk.related_talks // es. [{id, title, score}]
            }),
        };

    } catch (err) {
        console.error("Errore:", err);
        return {
            statusCode: 500,
            body: JSON.stringify({ errore: "Errore interno" }),
        };
    } finally {
        await client.close();
    }
};
