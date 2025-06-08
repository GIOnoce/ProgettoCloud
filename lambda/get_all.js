const connectToDatabase = require('./db');
const Talk = require('./Talk');

module.exports.get_all = async (event, context) => {
    // Previene attesa del loop eventi vuoto
    context.callbackWaitsForEmptyEventLoop = false;
    
    try {
        console.log('Starting handler execution...');
        
        console.log('Attempting to connect to database...');
        await connectToDatabase();
        console.log('Database connection successful');
        
        // Recupero talk con campi essenziali e ottimizzazioni performance
        console.log('Attempting to fetch talks...');
        const talks = await Talk.find({})
            .select('_id title url speakers')
            .sort({ title: 1 })
            .limit(500)
            .lean();
        
        console.log(`Found ${talks.length} talks`);
        const totalCount = talks.length;
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, OPTIONS'
            },
            body: JSON.stringify({
                success: true,
                data: talks,
                count: totalCount,
                message: `Retrieved ${totalCount} talks successfully`
            })
        };
        
    } catch (error) {
        console.error('Error retrieving talks:', error);
        console.error('Error stack:', error.stack);
        console.error('Error message:', error.message);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, OPTIONS'
            },
            body: JSON.stringify({
                success: false,
                error: 'Internal server error',
                message: 'Failed to retrieve talks',
                debug: process.env.NODE_ENV === 'development' ? error.message : undefined
            })
        };
    }
};

// Gestione richieste OPTIONS per CORS preflight
exports.options = async (event, context) => {
    return {
        statusCode: 200,
        headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET, OPTIONS'
        },
        body: ''
    };
};
