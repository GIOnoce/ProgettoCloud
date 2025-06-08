const Talk = require('./Talk');
const connect_to_db = require('./db');

module.exports.update_percentage = async (event, context) => {
    try {
        await connect_to_db();
        
        // Parsing dei parametri di input
        let talkId, feedback, userId;
        
        if (event.body) {
            const body = JSON.parse(event.body);
            talkId = body.talkId || body.id;
            feedback = body.feedback;
            userId = body.userId;
        } else if (event.queryStringParameters) {
            talkId = event.queryStringParameters.talkId || event.queryStringParameters.id;
            feedback = event.queryStringParameters.feedback;
            userId = event.queryStringParameters.userId;
        }
        
        if (!talkId || !feedback) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'Missing required parameters: talkId and feedback'
                })
            };
        }

        const talk = await Talk.findById(talkId);
        
        if (!talk) {
            return {
                statusCode: 404,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'Talk not found'
                })
            };
        }

        // Inizializzazione struttura feedback
        if (!talk.comprehend_analysis) {
            talk.comprehend_analysis = {};
        }
        
        if (!talk.comprehend_analysis.user_feedback) {
            talk.comprehend_analysis.user_feedback = {
                total_interactions: 0,
                positive_feedback: 0,
                negative_feedback: 0,
                score_adjustments: [],
                current_boost_score: 0
            };
        }
        
        const userFeedback = talk.comprehend_analysis.user_feedback;
        
        // Elaborazione feedback con logica 80/20
        let feedbackValue = 0;
        
        if (typeof feedback === 'string') {
            switch (feedback.toLowerCase()) {
                case 'positive':
                case 'like':
                case 'thumbs_up':
                    feedbackValue = 1;
                    userFeedback.positive_feedback += 1;
                    break;
                case 'negative':
                case 'dislike':
                case 'thumbs_down':
                    feedbackValue = -1;
                    userFeedback.negative_feedback += 1;
                    break;
                default:
                    feedbackValue = 0;
            }
        } else if (typeof feedback === 'number') {
            feedbackValue = Math.max(-1, Math.min(1, feedback));
            if (feedbackValue > 0) {
                userFeedback.positive_feedback += 1;
            } else if (feedbackValue < 0) {
                userFeedback.negative_feedback += 1;
            }
        }
        
        userFeedback.total_interactions += 1;
        
        // Applicazione regola 80/20 per aggiustamento score
        const currentBoost = userFeedback.current_boost_score;
        const newBoost = (currentBoost * 0.8) + (feedbackValue * 0.2);
        
        userFeedback.current_boost_score = Math.max(-0.5, Math.min(0.5, newBoost));
        
        // Memorizzazione storico aggiustamenti (ultimi 10)
        userFeedback.score_adjustments.push({
            timestamp: new Date(),
            feedback_value: feedbackValue,
            previous_boost: currentBoost,
            new_boost: userFeedback.current_boost_score,
            user_id: userId || 'anonymous'
        });
        
        if (userFeedback.score_adjustments.length > 10) {
            userFeedback.score_adjustments = userFeedback.score_adjustments.slice(-10);
        }
        
        const totalFeedback = userFeedback.positive_feedback + userFeedback.negative_feedback;
        const positiveRatio = totalFeedback > 0 ? userFeedback.positive_feedback / totalFeedback : 0.5;
        
        userFeedback.positive_ratio = positiveRatio;
        userFeedback.last_updated = new Date();
        
        // Aggiornamento score dei talk correlati
        if (Math.abs(userFeedback.current_boost_score) > 0.1) {
            await updateRelatedTalksScores(talkId, userFeedback.current_boost_score);
        }
        
        await talk.save();
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: true,
                talkId: talkId,
                updatedScores: {
                    current_boost_score: userFeedback.current_boost_score,
                    positive_ratio: positiveRatio,
                    total_interactions: userFeedback.total_interactions
                },
                feedback_processed: {
                    feedback_value: feedbackValue,
                    feedback_type: typeof feedback === 'string' ? feedback : 'numeric'
                }
            })
        };
        
    } catch (error) {
        console.error('Error in update_percentage:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'Internal server error',
                message: error.message
            })
        };
    }
};

// Funzione helper per aggiornare score nei talk correlati
async function updateRelatedTalksScores(targetTalkId, boostScore) {
    try {
        const talksWithRelation = await Talk.find({
            'related_talks.id': targetTalkId
        });
        
        // Aggiornamento con boost attenuato (10% dell'originale)
        const updatePromises = talksWithRelation.map(async (talk) => {
            const relatedTalk = talk.related_talks.find(rt => rt.id === targetTalkId);
            if (relatedTalk) {
                const dampedBoost = boostScore * 0.1;
                relatedTalk.score = Math.max(0, Math.min(1, relatedTalk.score + dampedBoost));
                
                talk.markModified('related_talks');
                return talk.save();
            }
        });
        
        await Promise.all(updatePromises.filter(promise => promise !== undefined));
        
        console.log(`Updated related talk scores for ${talksWithRelation.length} talks`);
        
    } catch (error) {
        console.error('Error updating related talks scores:', error);
    }
}
