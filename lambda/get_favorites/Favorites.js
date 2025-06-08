const mongoose = require('mongoose');

const favorites_schema = new mongoose.Schema({
    talkId: {
        type: String,
        required: true,
        unique: true, // Utente singolo, quindi talkId dovrebbe essere unico
        ref: 'talk'
    },
    dateAdded: {
        type: Date,
        default: Date.now
    },
    // Memorizza alcune informazioni del talk per accesso rapido senza join
    talkData: {
        title: String,
        speakers: String,
        url: String
    }
}, {
    collection: 'favorites'
});

module.exports = mongoose.model('favorites', favorites_schema);
