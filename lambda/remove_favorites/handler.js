const mongoose = require('mongoose');
const connect_to_db = require('./db');
const Favorites = require('./favorites');

module.exports.remove_favorites = async (event) => {
    await connect_to_db();
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE'
    };

    if (event.httpMethod === 'OPTIONS') {
        return { statusCode: 200, headers, body: '' };
    }

    try {
        const body = JSON.parse(event.body);
        const { talkId } = body;

        if (!talkId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({ 
                    error: 'talkId è richiesto' 
                })
            };
        }

        const result = await Favorites.deleteOne({
            talkId: talkId
        });

        if (result.deletedCount === 0) {
            return {
                statusCode: 404,
                headers,
                body: JSON.stringify({ message: 'Preferito non trovato' })
            };
        }

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ message: 'Rimosso dai preferiti' })
        };

    } catch (error) {
        console.error('Errore rimuovendo dai preferiti:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
                error: 'Errore interno del server',
                details: error.message 
            })
        };
    }
};
