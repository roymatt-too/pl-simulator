---
title: "Building an AI-Powered Telegram Bot with Claude API and n8n: A Complete Guide"
published: true
description: "Learn how to build a fully functional AI-powered Telegram bot using Claude API and n8n. No traditional backend required. Step-by-step tutorial with workflow JSON included."
tags: ai, automation, tutorial, n8n
cover_image:
canonical_url:
series: "AI Automation with n8n"
---

*Build a production-ready AI chatbot on Telegram using Anthropic's Claude API and n8n in under 30 minutes, with zero traditional backend code.*

---

## Why Claude API + Telegram + n8n?

If you've ever wanted to deploy an AI assistant that real users can interact with instantly, you've probably faced a familiar dilemma: write a full backend from scratch, or cobble together fragile scripts that break at 3 AM.

There's a better way. By combining three tools — **Claude API** for intelligence, **Telegram** for the user interface, and **n8n** for orchestration — you get a production-grade chatbot with:

- **Claude 3.5 Sonnet / Claude 4** as the reasoning engine — far more nuanced than GPT for following complex instructions
- **Telegram** as a zero-friction UI that 900M+ users already have installed
- **n8n** as the glue layer — visual workflow automation that you self-host, so there are no per-execution fees like Zapier

I've been running this exact stack for [OpenClaw](https://t.me/OpenClawBot), an AI-powered Telegram agent, and it handles thousands of messages daily without a single line of Express.js. Let me show you how to build it.

---

## Prerequisites

Before we start, make sure you have:

| Requirement | Details |
|---|---|
| **Node.js** | v18+ (required for n8n) |
| **n8n** | Self-hosted or n8n Cloud account |
| **Anthropic API Key** | Get one at [console.anthropic.com](https://console.anthropic.com) |
| **Telegram Account** | To create a bot via BotFather |

Estimated cost: ~$0.003 per message with Claude 3.5 Sonnet. For most personal-use bots, you'll spend less than $5/month.

---

## Step 1: Create Your Telegram Bot with BotFather

Open Telegram and search for **@BotFather**. This is Telegram's official bot for creating bots.

```
/start
/newbot
```

BotFather will ask two questions:

1. **Bot name**: The display name (e.g., "My Claude Assistant")
2. **Bot username**: Must end in `bot` (e.g., `my_claude_assistant_bot`)

You'll receive a **Bot Token** that looks like this:

```
7123456789:AAH_your-token-string-here
```

Save this token — you'll need it in Step 3.

### Optional but Recommended: Configure Bot Settings

```
/setdescription - Add a description for your bot
/setabouttext   - Set the "About" section
/setuserpic     - Upload a profile picture
/setcommands    - Define command menu
```

Here's a useful command list to set via `/setcommands`:

```
start - Start the bot
help - Show available commands
clear - Reset conversation context
```

---

## Step 2: Install and Set Up n8n

### Option A: Self-Hosted (Recommended for Production)

```bash
# Install n8n globally
npm install -g n8n

# Or use Docker (preferred for production)
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e WEBHOOK_URL=https://your-domain.com/ \
  n8nio/n8n
```

> **Important**: For Telegram webhooks to work, n8n must be accessible via HTTPS on a public URL. If you're developing locally, use a tunnel service like `ngrok` or `cloudflared`.

```bash
# Quick tunnel for local development
npx ngrok http 5678
```

### Option B: n8n Cloud

Sign up at [app.n8n.cloud](https://app.n8n.cloud). The free tier gives you 2,500 executions/month — more than enough for testing. Webhooks work out of the box, no tunnel required.

### Verify Installation

Open `http://localhost:5678` (or your cloud URL). You should see the n8n canvas editor. Create a new workflow and name it **"Claude Telegram Bot"**.

---

## Step 3: Configure the Telegram Trigger Node

In your new workflow, click **"Add first step"** and search for **Telegram**.

Select **"Telegram Trigger"** — this node listens for incoming messages to your bot.

### Configure Credentials

1. Click **"Create New Credential"**
2. Paste your Bot Token from Step 1
3. Click **"Save"**

### Trigger Settings

| Setting | Value |
|---|---|
| **Updates** | `message` |
| **Additional Fields** | Leave default |

The node configuration JSON:

```json
{
  "parameters": {
    "updates": ["message"]
  },
  "name": "Telegram Trigger",
  "type": "n8n-nodes-base.telegramTrigger",
  "typeVersion": 1.1,
  "position": [250, 300],
  "credentials": {
    "telegramApi": {
      "id": "YOUR_CREDENTIAL_ID",
      "name": "Telegram Bot"
    }
  }
}
```

### Test the Trigger

1. Click **"Listen for test event"** in n8n
2. Send any message to your bot on Telegram
3. You should see the incoming message data appear in n8n

The payload includes `message.text`, `message.chat.id`, `message.from.first_name`, and more. We'll use these fields in subsequent steps.

---

## Step 4: Connect the Claude API (Anthropic Node)

Add a new node after the Telegram Trigger. Search for **"Anthropic"** or **"HTTP Request"**.

### Option A: Using the Built-in Anthropic Node (n8n v1.30+)

n8n v1.30+ ships with a native Anthropic node. Configure it as follows:

1. **Credential**: Add your Anthropic API key
2. **Model**: `claude-sonnet-4-20250514` (best balance of speed, quality, and cost)
3. **Prompt**: Use an expression to inject the user's Telegram message:

```
{{ $json.message.text }}
```

### Option B: Using HTTP Request Node (Any n8n Version)

If your n8n version doesn't have the native Anthropic node, the HTTP Request node works perfectly:

```json
{
  "parameters": {
    "method": "POST",
    "url": "https://api.anthropic.com/v1/messages",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpHeaderAuth",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "x-api-key",
          "value": "YOUR_ANTHROPIC_API_KEY"
        },
        {
          "name": "anthropic-version",
          "value": "2023-06-01"
        },
        {
          "name": "content-type",
          "value": "application/json"
        }
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ JSON.stringify({ model: 'claude-sonnet-4-20250514', max_tokens: 1024, system: 'You are a helpful AI assistant on Telegram. Keep responses concise and formatted for mobile reading. Use short paragraphs and bullet points when appropriate.', messages: [{ role: 'user', content: $json.message.text }] }) }}"
  },
  "name": "Claude API",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "position": [500, 300]
}
```

### System Prompt Best Practices for Telegram Bots

The system prompt determines your bot's personality and behavior. Here's one that works well:

```text
You are a helpful AI assistant on Telegram. Follow these rules:
1. Keep responses under 4096 characters (Telegram's message limit).
2. Use short paragraphs — mobile screens are small.
3. Use bullet points and numbered lists for structured information.
4. If a question is ambiguous, give the most likely answer first,
   then briefly mention alternatives.
5. Format code blocks with triple backticks and language identifiers.
```

---

## Step 5: Send the Response Back to Telegram

Add a **"Telegram"** node (the action node, not the Trigger) after the Claude API node.

### Configuration

| Setting | Value |
|---|---|
| **Resource** | Send Message |
| **Chat ID** | `{{ $('Telegram Trigger').item.json.message.chat.id }}` |
| **Text** | Depends on Step 4 method (see below) |
| **Parse Mode** | Markdown |

For the **Text** field:

**If using the native Anthropic node:**
```
{{ $json.message.content[0].text }}
```

**If using the HTTP Request node:**
```
{{ $json.content[0].text }}
```

### Handle Long Responses

Telegram enforces a 4096-character limit per message. Add a **Code node** between Claude API and the Telegram send node to split long responses:

```javascript
const text = $input.first().json.content[0].text;
const chatId = $('Telegram Trigger').first().json.message.chat.id;
const maxLength = 4000; // Leave buffer for Markdown formatting

if (text.length <= maxLength) {
  return [{ json: { chatId, text } }];
}

// Split into chunks at natural paragraph boundaries
const chunks = [];
let remaining = text;

while (remaining.length > 0) {
  if (remaining.length <= maxLength) {
    chunks.push(remaining);
    break;
  }

  let splitIndex = remaining.lastIndexOf('\n\n', maxLength);
  if (splitIndex === -1) splitIndex = remaining.lastIndexOf('\n', maxLength);
  if (splitIndex === -1) splitIndex = remaining.lastIndexOf(' ', maxLength);
  if (splitIndex === -1) splitIndex = maxLength;

  chunks.push(remaining.substring(0, splitIndex));
  remaining = remaining.substring(splitIndex).trimStart();
}

return chunks.map(chunk => ({ json: { chatId, text: chunk } }));
```

Then update the Telegram send node to use `{{ $json.text }}` for the text and `{{ $json.chatId }}` for the chat ID.

---

## Step 6: Error Handling and Fallback

Production bots need graceful error handling. Here's how to make yours resilient.

### Add an Error Trigger Workflow

Create a separate workflow called **"Bot Error Handler"**:

1. Add an **Error Trigger** node
2. Connect it to a **Telegram Send Message** node
3. Configure the error message:

```
Sorry, I encountered an error processing your request.
Please try again in a moment.

If this persists, use /clear to reset the conversation.
```

### Rate Limiting

Claude API has rate limits, and users sometimes spam messages. Add a **Code node** before the API call:

```javascript
const chatId = $json.message.chat.id;
const now = Date.now();
const rateLimitMs = 2000; // Minimum 2 seconds between messages

// Use n8n's static data for cross-execution persistence
const state = $getWorkflowStaticData('global');
const key = 'lastMsg_' + chatId;

if (state[key] && (now - state[key]) < rateLimitMs) {
  return []; // Skip processing — too fast
}

state[key] = now;
return [$input.first()];
```

### API Error Detection

Add an **IF node** after the Claude API call to check for errors:

- **Condition**: `{{ $json.error ? true : false }}`
- **True branch**: Send an apologetic fallback message to the user
- **False branch**: Continue to the response formatting and Telegram send node

### Input Validation

Add another Code node before the API call to filter out non-text messages:

```javascript
const message = $json.message;

// Skip if no text content (e.g., stickers, images, etc.)
if (!message.text || message.text.trim() === '') {
  return [];
}

// Skip bot commands that should be handled separately
if (message.text.startsWith('/clear') || message.text.startsWith('/help')) {
  return [];
}

return [$input.first()];
```

---

## Step 7: Deployment and Production Tips

### Use a VPS for Self-Hosting

A $6/month DigitalOcean droplet (or equivalent) is ideal. Here's a production-ready Docker Compose configuration:

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=your-domain.com
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://your-domain.com/
      - NODE_ENV=production
      - N8N_ENCRYPTION_KEY=your-random-encryption-key
      - ANTHROPIC_API_KEY=sk-ant-xxxxx
    volumes:
      - n8n_data:/home/node/.n8n

  caddy:
    image: caddy:2
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data

volumes:
  n8n_data:
  caddy_data:
```

**Caddyfile** for automatic HTTPS:

```
your-domain.com {
    reverse_proxy n8n:5678
}
```

Deploy with:

```bash
docker compose up -d
```

Caddy automatically provisions and renews SSL certificates via Let's Encrypt. No manual HTTPS configuration needed.

### Monitoring

Create a separate n8n workflow with a **Schedule Trigger** (every 5 minutes) that pings your bot and alerts you if it's down. Route the alert branch to your personal Telegram, email, or Slack.

### Cost Optimization Strategies

| Strategy | Estimated Savings |
|---|---|
| Cache frequent questions with a **Redis** or **Postgres** lookup | 30-50% fewer API calls |
| Route simple queries to `claude-3-haiku`, complex ones to `claude-sonnet-4-20250514` | ~60% cost reduction |
| Set `max_tokens` based on expected response length | Prevents paying for unused token capacity |
| Add a "typing..." indicator while Claude processes | Improves UX, reduces duplicate messages |

---

## Complete Workflow JSON (Import-Ready)

Here's the full n8n workflow you can import directly into your instance:

```json
{
  "name": "Claude Telegram Bot",
  "nodes": [
    {
      "parameters": {
        "updates": ["message"]
      },
      "name": "Telegram Trigger",
      "type": "n8n-nodes-base.telegramTrigger",
      "typeVersion": 1.1,
      "position": [250, 300],
      "credentials": {
        "telegramApi": {
          "id": "1",
          "name": "Telegram Bot"
        }
      }
    },
    {
      "parameters": {
        "method": "POST",
        "url": "https://api.anthropic.com/v1/messages",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            { "name": "x-api-key", "value": "={{ $env.ANTHROPIC_API_KEY }}" },
            { "name": "anthropic-version", "value": "2023-06-01" },
            { "name": "content-type", "value": "application/json" }
          ]
        },
        "sendBody": true,
        "specifyBody": "json",
        "jsonBody": "={{ JSON.stringify({ model: 'claude-sonnet-4-20250514', max_tokens: 1024, system: 'You are a helpful AI assistant on Telegram. Keep responses concise and formatted for mobile reading.', messages: [{ role: 'user', content: $json.message.text }] }) }}"
      },
      "name": "Claude API",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [500, 300],
      "credentials": {
        "httpHeaderAuth": {
          "id": "2",
          "name": "Anthropic API"
        }
      }
    },
    {
      "parameters": {
        "chatId": "={{ $('Telegram Trigger').item.json.message.chat.id }}",
        "text": "={{ $json.content[0].text }}",
        "additionalFields": {
          "parse_mode": "Markdown"
        }
      },
      "name": "Send Response",
      "type": "n8n-nodes-base.telegram",
      "typeVersion": 1.2,
      "position": [750, 300],
      "credentials": {
        "telegramApi": {
          "id": "1",
          "name": "Telegram Bot"
        }
      }
    }
  ],
  "connections": {
    "Telegram Trigger": {
      "main": [[{ "node": "Claude API", "type": "main", "index": 0 }]]
    },
    "Claude API": {
      "main": [[{ "node": "Send Response", "type": "main", "index": 0 }]]
    }
  }
}
```

**To import**: In n8n, go to **Workflows > Import from File/URL** and paste this JSON.

---

## What's Next

Once your basic bot is running, here are the most impactful enhancements:

1. **Conversation memory** — Store chat history in Postgres or Redis, and send previous messages as context to Claude for multi-turn conversations
2. **Tool use** — Leverage Claude's function calling to let your bot search the web, check weather, query databases, or call external APIs
3. **Multi-modal input** — Handle images sent to the bot using Claude's vision capabilities
4. **User authentication** — Restrict access to authorized Telegram user IDs using an allowlist
5. **Analytics dashboard** — Log all interactions to Google Sheets or a database for usage insights

I'm building all of these into [OpenClaw](https://t.me/OpenClawBot). Follow me for the next article in this series.

---

## Wrapping Up

The Claude API + Telegram + n8n stack is one of the fastest paths from idea to production AI bot. You get Claude's reasoning quality, Telegram's massive user base, and n8n's visual workflow builder — all without writing a traditional backend.

**Total cost**: ~$6/month for a VPS plus a few dollars in API usage. Compare that to enterprise chatbot platforms charging $200+/month.

The complete workflow JSON above is ready to import. Add your API keys, and you'll have a working AI bot in under 30 minutes.

If this was helpful, drop a reaction and follow me for Part 2 where we add conversation memory and Claude's tool-use capabilities.

---

*[Ryosuke Matsumiya](https://dev.to/sushihey) — AI Automation Engineer. Building [OpenClaw](https://t.me/OpenClawBot), an AI-powered Telegram agent. Passionate about n8n, Claude API, and workflow automation.*