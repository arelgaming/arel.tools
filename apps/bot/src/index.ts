import { Client, GatewayIntentBits } from "discord.js";

export function startBot() {
  const client = new Client({
    intents: [GatewayIntentBits.Guilds],
  });

  client.once("ready", (c) => {
    console.log(`Bot logged in as ${c.user.tag}`);
  });

  const token = process.env["DISCORD_BOT_TOKEN"];
  if (!token) {
    console.error("DISCORD_BOT_TOKEN is not set");
    process.exit(1);
  }

  client.login(token);
  return client;
}

startBot();
