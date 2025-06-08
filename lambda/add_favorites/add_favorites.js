const mongoose = require('mongoose');
const connect_to_db = require('./db');
const Talk = require('./Talk');
const Favorites = require('./favorites');

module.exports.add_favorites = async (event) => {
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

        const talk = await Talk.findById(talkId);
        if (!talk) {
            return {
                statusCode: 404,
                headers,
                body: JSON.stringify({ error: 'Talk non trovato' })
            };
        }

        // Tenta di creare il preferito (fallirà se già esistente a causa dell'indice unico)
        try {
            const favorite = new Favorites({
                talkId: talkId,
                talkData: {
                    title: talk.title,
                    speakers: talk.speakers,
                    url: talk.url
                }
            });

            await favorite.save();

            return {
                statusCode: 201,
                headers,
                body: JSON.stringify({ 
                    message: 'Aggiunto ai preferiti',
                    favoriteId: favorite._id
                })
            };
        } catch (duplicateError) {
            if (duplicateError.code === 11000) {
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({ message: 'Già nei preferiti' })
                };
            }
            throw duplicateError;
        }

    } catch (error) {
        console.error('Errore aggiungendo ai preferiti:', error);
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
