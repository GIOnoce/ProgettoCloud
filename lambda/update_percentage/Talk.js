const mongoose = require('mongoose');

const talk_schema = new mongoose.Schema({
    _id: String, 
    title: String,
    url: String,
    description: String,
    speakers: String,
    comprehend_analysis: mongoose.Schema.Types.Mixed,
    related_talks: [{ 
        id: String,
        score: Number,
        title: String,
        presenter: String
    }]
}, {
    collection: 'tedx_data',
});

module.exports = mongoose.model('talk', talk_schema);
