//Import Dependencies
const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();

//Lambda Handler Function
//Processes the incoming event from SQS
exports.handler = async (event) => {
    //Loop Through Each Record in the Event
    for (const record of event.Records) {
        let body;
        
        try {
            //Parse the JSON Message Body
            body = JSON.parse(record.body);
            console.log('Received message body:', body);

        } catch (error) {
            console.error('Failed to parse message body:', record.body);
            continue; //Skip this record and move to the next one
        }

        //Validate and Process the Message
        if (body.key && body.key.id) {
            const id = body.key.id;

            //Set Up Parameters for DynamoDB
            const params = {
                TableName: process.env.TABLE_NAME,
                Item: {
                    id: id,
                    //Add other attributes here if needed
                }
            };

            //Insert Item into DynamoDB
            try {
                await dynamo.put(params).promise();
                console.log(`Successfully inserted item with id: ${id}`);
            } catch (error) {
                console.error(`Failed to insert item with id: ${id}`, error);
            }
        } else {
            //Handle Invalid Message
            console.error('Invalid message body, missing key.id:', body);
        }
    }
};
