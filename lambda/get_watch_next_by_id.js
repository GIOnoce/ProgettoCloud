const connect_to_db = require('./db');
const Talk = require('./Talk');

module.exports.get_watch_next_by_id = async (event) => {
    try {
        await connect_to_db();

        // Estrazione talkId da diversi parametri
        let talkId;
        if (event.pathParameters && event.pathParameters.talkId) {
            talkId = event.pathParameters.talkId;
        } else if (event.queryStringParameters && event.queryStringParameters.talkId) {
            talkId = event.queryStringParameters.talkId;
        } else if (event.body) {
            const body = JSON.parse(event.body);
            talkId = body.talkId || body.id;
        }

        console.log('--- Debugging talkId Parsing ---');
        console.log('Event received:', JSON.stringify(event));
        console.log('Raw talkId extracted:', talkId);

        if (!talkId) {
            return {
                statusCode: 400,
                body: JSON.stringify({ error: 'Missing talkId parameter' }),
            };
        }

        const talkIdStr = String(talkId);
        console.log('talkIdStr for MongoDB query:', talkIdStr, ' (Type:', typeof talkIdStr + ')');

        // Strategie multiple per trovare il talk
        let talk = null;
        
        console.log('Strategy 1: Querying by _id...');
        talk = await Talk.findOne({ _id: talkIdStr }).exec();
        
        if (!talk) {
            console.log('Strategy 2: Querying by slug...');
            talk = await Talk.findOne({ slug: talkIdStr }).exec();
        }
        
        if (!talk) {
            console.log('Strategy 3: Querying by url...');
            talk = await Talk.findOne({ url: talkIdStr }).exec();
        }
        
        if (!talk) {
            console.log('Strategy 4: Querying by id field...');
            talk = await Talk.findOne({ id: talkIdStr }).exec();
        }
        
        // Ricerca parziale per titolo
        if (!talk) {
            console.log('Strategy 5: Trying partial matches...');
            const titlePattern = talkIdStr.replace(/_/g, ' ').replace(/ted_\w+_/, '');
            talk = await Talk.findOne({ 
                title: { $regex: titlePattern, $options: 'i' } 
            }).exec();
        }

        console.log('Final result:', talk ? 'Talk found' : 'Talk NOT found');
        
        if (!talk) {
            const sampleTalks = await Talk.find().limit(5).select('_id id slug url title').exec();
            console.log('Sample available talks for debugging:');
            sampleTalks.forEach(t => {
                console.log(`  - _id: ${t._id}, id: ${t.id}, slug: ${t.slug}, title: ${t.title}`);
            });
            
            return {
                statusCode: 404,
                body: JSON.stringify({ 
                    error: 'Talk not found',
                    searchedId: talkIdStr,
                    availableSamples: sampleTalks.map(t => ({
                        _id: t._id,
                        id: t.id,
                        slug: t.slug,
                        title: t.title
                    }))
                }),
            };
        }

        // Ordinamento e selezione talk correlati
        const relatedTalks = talk.related_talks || [];
        relatedTalks.sort((a, b) => (b.score || 0) - (a.score || 0));
        const relatedIds = relatedTalks.slice(0, 10).map(rt => rt.id);

        console.log('Related IDs for second query:', relatedIds);

        // Query per talk suggeriti con strategie multiple
        let suggestedTalks = [];
        
        if (relatedIds.length > 0) {
            suggestedTalks = await Talk.find({ _id: { $in: relatedIds.map(String) } })
                .select('_id id slug title url description speakers comprehend_analysis related_talks')
                .lean()
                .exec();
            
            if (suggestedTalks.length === 0) {
                suggestedTalks = await Talk.find({ 
                    $or: [
                        { _id: { $in: relatedIds.map(String) } },
                        { id: { $in: relatedIds.map(String) } },
                        { slug: { $in: relatedIds.map(String) } }
                    ]
                })
                .select('_id id slug title url description speakers comprehend_analysis related_talks')
                .lean()
                .exec();
            }
        }

        // Abbinamento score ai talk suggeriti
        const suggestedTalksWithScore = suggestedTalks.map(t => {
            const rel = relatedTalks.find(rt => 
                rt.id === t._id || rt.id === t.id || rt.id === t.slug
            );
            return {
                id: t._id || t.id || t.slug,
                title: t.title,
                url: t.url,
                description: t.description,
                speakers: t.speakers,
                score: rel ? rel.score : 0,
            };
        });

        return {
            statusCode: 200,
            body: JSON.stringify({ 
                talk: {
                    ...talk.toObject(),
                    id: talk._id || talk.id || talk.slug
                }, 
                suggestions: suggestedTalksWithScore 
            }),
        };
    } catch (error) {
        console.error('Error in get_watch_next_by_id:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ 
                error: 'Internal server error',
                details: error.message 
            }),
        };
    }
};
