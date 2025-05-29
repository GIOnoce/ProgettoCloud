// handler.js
// Entry point della Lambda

const { connectToDatabase } = require('./db');
const { getRelatedTalks } = require('./Talk');

exports.handler = async (event) => {
  const talkId = event.queryStringParameters?.id;

  if (!talkId) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Parametro 'id' mancante" })
    };
  }

  try {
    const db = await connectToDatabase();
    const result = await getRelatedTalks(db, talkId);

    if (!result) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: "Talk non trovato" })
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify(result)
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
