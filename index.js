const AWS = require('aws-sdk');
const dynamoDb = new AWS.DynamoDB.DocumentClient();

exports.handler = async function(event) {
  console.log("Received event:", JSON.stringify(event, null, 2));

  for (const record of event.Records) {
    const messageBody = JSON.parse(record.body);
    const params = {
      TableName: process.env.TABLE_NAME,
      Item: {
        id: messageBody.id,
        data: messageBody.data,
      },
    };

    try {
      await dynamoDb.put(params).promise();
      console.log(`Successfully inserted item with id: ${messageBody.id}`);
    } catch (err) {
      console.error(`Failed to insert item with id: ${messageBody.id}`, err);
    }
  }
};
