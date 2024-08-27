const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    for (const record of event.Records) {
        const body = JSON.parse(record.body);
        console.log("Received message body:", body);

        if (body.key && body.key.id) {
            const id = body.key.id;

            const params = {
                TableName: process.env.TABLE_NAME,
                Item: {
                    id: id,
                    // You can add other attributes here if needed
                }
            };

            try {
                await dynamo.put(params).promise();
                console.log(`Successfully inserted item with id: ${id}`);
            } catch (error) {
                console.error(`Failed to insert item with id: ${id}`, error);
            }
        } else {
            console.error('Invalid message body, missing key.id:', body);
        }
    }
};
