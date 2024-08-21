const { ServiceBroker } = require("moleculer");
const ApiService = require("moleculer-web");
const { getSecretValue } = require("./secretsManager");
const { exec } = require("child_process");
const util = require("util");
const execPromise = util.promisify(exec);


// Function to get NATS cluster nodes from Route 53
async function getNatsClusterNodes() {
  const hostedZoneId = process.env.ROUTE53_HOSTED_ZONE_ID;
  const recordName = "nats";

  try {
    // Find *nats record inside Route 53
    const { stdout } = await execPromise(
      `aws route53 list-resource-record-sets --hosted-zone-id ${hostedZoneId} --query "ResourceRecordSets[?starts_with(Name, '${recordName}')] | [*].Name" --output text`
    );

    // Split the output into individual record names
    const recordNames = stdout.split("\n").filter(Boolean);

    return recordNames;
  } catch (error) {
    logger.error("Failed to retrieve NATS cluster record names from Route 53:", error);
    throw error;
  }
}


async function initBroker() {
  try {
    const secretString = await getSecretValue(process.env.SECRET_ID);
    const secretData = JSON.parse(secretString);

    const clusterNodes = await getNatsClusterNodes();
    const natsServers = clusterNodes.map((node) => `nats://${node}:4222`).join(",");
    return new ServiceBroker({ // Connect with options
      transporter: {
          type: "NATS",
          options: {
              servers: [ natsServers ],
              user: secretData.username,
              pass: secretData.password
          }
      }
    });
  } catch (error) {
    logger.error("Failed to initialize the broker:", error);
    throw error;
  }
}

// Function to refresh the broker's NATS configuration
async function refreshBrokerConfig(broker) {
  try {
    const clusterNodes = await getNatsClusterNodes();
    const natsServers = clusterNodes.map((node) => `nats://${node}:4222`).join(",");
    broker.transporter.options.url = natsServers; // Update to comma-separated string
    logger.info("NATS servers updated:", { natsServers });
  } catch (error) {
    logger.error("Failed to update NATS servers:", error);
  }
}

// Start the broker
initBroker()
  .then((broker) => {
    broker.createService({
      mixins: [ApiService],

      settings: {
          routes: [{
              aliases: {
                  "api": "service1.action1",
                  "health": "$node.health"
              }
          }]
      }
    });

    broker.start().then(() => {
      console.log("API Service started.");
    });

    // Periodically refresh NATS configuration every 5 minutes
    setInterval(() => {
      refreshBrokerConfig(broker);
    }, 5 * 60 * 1000); // 5 minutes
})
.catch((error) => {
  logger.error("Failed to initialize the broker:", error);
  process.exit(1);
});