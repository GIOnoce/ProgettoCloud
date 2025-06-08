const mongoose = require('mongoose');
const connect_to_db = require('./db');
const Favorites = require('./favorites');
const Talk = require('./Talk');

module.exports.get_favorites = async (event) => {
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
        const favorites = await Favorites.find({})
            .sort({ dateAdded: -1 });

        const talkIds = favorites.map(fav => fav.talkId);
        const talks = await Talk.find({ _id: { $in: talkIds } });

        // Crea una mappa per ricerca rapida
        const talkMap = {};
        talks.forEach(talk => {
            talkMap[talk._id] = talk;
        });

        const favoritesWithTalks = favorites.map(favorite => {
            const talk = talkMap[favorite.talkId];
            return {
                favoriteId: favorite._id,
                dateAdded: favorite.dateAdded,
                talk: talk || {
                    _id: favorite.talkId,
                    title: favorite.talkData.title,
                    speakers: favorite.talkData.speakers,
                    url: favorite.talkData.url,
                    description: 'Dettagli del talk non disponibili',
                    comprehend_analysis: { KeyPhrases: [] }
                }
            };
        });

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                favorites: favoritesWithTalks,
                count: favoritesWithTalks.length
            })
        };

    } catch (error) {
        console.error('Errore ottenendo i preferiti:', error);
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
