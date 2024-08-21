const AWS = require('aws-sdk');

// Configure AWS SDK
AWS.config.update({ region: 'ap-southeast-1' });

// Create a Secrets Manager client
const secretsManager = new AWS.SecretsManager();

async function getSecretValue(secretName) {
    try {
        const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
        if ('SecretString' in data) {
            return data.SecretString;
        } else {
            // If the secret is binary
            let buff = Buffer.from(data.SecretBinary, 'base64');
            return buff.toString('ascii');
        }
    } catch (err) {
        console.error("Error retrieving secret:", err);
        throw err;
    }
}

module.exports = {
    getSecretValue
};
