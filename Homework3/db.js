// db.js
// Gestione connessione a MongoDB Atlas

const { MongoClient } = require('mongodb');

let cachedDb = null;

const uri = process.env.MONGODB_URI; // Definito in variabili d'ambiente Lambda

exports.connectToDatabase = async () => {
  if (cachedDb) {
    return cachedDb;
  }

  const client = new MongoClient(uri);
  await client.connect();
  cachedDb = client.db("mytedx_db"); // Nome database MongoDB
  return cachedDb;
};
