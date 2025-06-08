const mongoose = require('mongoose');
const connect_to_db = require('./db');
const Favorites = require('./favorites');

module.exports.check_favorite = async (event) => {
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
        const talkId = event.queryStringParameters?.talkId;

        if (!talkId) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({ 
                    error: 'talkId è richiesto' 
                })
            };
        }

        const favorite = await Favorites.findOne({
            talkId: talkId
        });

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ 
                isFavorite: !!favorite,
                favoriteId: favorite?._id 
            })
        };

    } catch (error) {
        console.error('Errore controllando stato preferito:', error);
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
