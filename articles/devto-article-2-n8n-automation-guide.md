---
title: "5 n8n Automation Workflows That Save Me 10+ Hours Every Week"
published: true
description: "Practical n8n workflow examples for lead management, social media scheduling, AI email drafting, web scraping, and Telegram task management. Complete JSON snippets included."
tags: automation, n8n, productivity, ai
cover_image:
canonical_url:
series: "AI Automation with n8n"
---

*I replaced Zapier, three Python scripts, and a VA with five n8n workflows. Here's exactly how each one works, with importable JSON.*

---

## Why n8n Over Zapier or Make?

Before diving into the workflows, let me address the obvious question: why n8n?

I've used Zapier (3 years), Make/Integromat (1 year), and n8n (2 years). Here's my honest comparison:

| Feature | Zapier | Make | n8n |
|---|---|---|---|
| **Pricing** | $29+/mo for 750 tasks | $9+/mo for 10K ops | **Free** (self-hosted) |
| **Self-hosting** | No | No | **Yes** |
| **Code nodes** | Limited | JavaScript only | **JavaScript + Python** |
| **AI integrations** | Basic | Basic | **Native Claude, GPT, etc.** |
| **Complex logic** | Painful | Better | **Full programming power** |
| **Data privacy** | Cloud only | Cloud only | **Your server, your data** |

The dealbreaker for me was cost. Running 50,000+ operations/month on Zapier would cost $100+. On n8n self-hosted, it costs the $6/month VPS fee — regardless of volume.

Let's look at the five workflows that save me the most time.

---

## Workflow 1: Automated Lead Management Pipeline

**Time saved: ~3 hours/week**

When a new lead fills out my contact form (Google Forms), this workflow automatically:

1. Adds the lead to a Google Sheet with a timestamp
2. Sends a personalized welcome email
3. Posts a notification to my team's Slack channel
4. Creates a follow-up reminder for 3 days later

### How It Works

The workflow starts with a **Google Forms Trigger** that fires whenever someone submits the form. A **Google Sheets** node appends the lead data to a tracking spreadsheet. Then it branches into three parallel paths: email, Slack notification, and a delayed follow-up.

### Key Nodes

```json
{
  "name": "Lead Pipeline",
  "nodes": [
    {
      "parameters": {
        "formId": "YOUR_FORM_ID"
      },
      "name": "New Form Submission",
      "type": "n8n-nodes-base.googleFormsTrigger",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "operation": "append",
        "sheetId": "YOUR_SHEET_ID",
        "range": "Leads!A:F",
        "columns": "timestamp,name,email,company,source,status"
      },
      "name": "Add to Sheet",
      "type": "n8n-nodes-base.googleSheets",
      "typeVersion": 4,
      "position": [450, 300]
    },
    {
      "parameters": {
        "resource": "message",
        "operation": "send",
        "to": "={{ $json.email }}",
        "subject": "Thanks for reaching out, {{ $json.name }}!",
        "emailType": "html",
        "message": "<h2>Hi {{ $json.name }},</h2><p>Thanks for your interest. I'll review your request and get back to you within 24 hours.</p>"
      },
      "name": "Welcome Email",
      "type": "n8n-nodes-base.gmail",
      "typeVersion": 2,
      "position": [650, 200]
    },
    {
      "parameters": {
        "channel": "#leads",
        "text": "New lead from {{ $json.name }} ({{ $json.company }})"
      },
      "name": "Slack Alert",
      "type": "n8n-nodes-base.slack",
      "typeVersion": 2,
      "position": [650, 400]
    }
  ]
}
```

### Pro Tip: Lead Scoring

Add a **Code node** after the Google Sheets node to score leads automatically:

```javascript
const lead = .first().json;
let score = 0;

// Score based on company size indicators
if (lead.company && lead.company.length > 0) score += 20;
if (lead.source === 'referral') score += 30;
if (lead.source === 'google') score += 10;

// Add score to the data
return [{ json: { ...lead, leadScore: score, priority: score >= 30 ? 'high' : 'normal' } }];
```

---

## Workflow 2: Social Media Auto-Scheduling

**Time saved: ~2 hours/week**

I write content in a Google Doc once a week. This workflow takes that content and schedules posts across multiple platforms.

### How It Works

A **Schedule Trigger** runs every Monday at 9 AM. It reads a Google Sheet containing pre-written posts (with columns for platform, content, and scheduled time). For each row marked as "pending," it posts to the appropriate platform via API and updates the status to "posted."

### Key Nodes

```json
{
  "name": "Social Media Scheduler",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [{ "triggerAtHour": 9, "triggerAtDay": 1 }]
        }
      },
      "name": "Monday 9AM",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "operation": "read",
        "sheetId": "YOUR_SHEET_ID",
        "range": "Posts!A:E"
      },
      "name": "Get Pending Posts",
      "type": "n8n-nodes-base.googleSheets",
      "typeVersion": 4,
      "position": [450, 300]
    },
    {
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{ $json.platform }}",
              "value2": "twitter"
            }
          ]
        }
      },
      "name": "Route by Platform",
      "type": "n8n-nodes-base.switch",
      "typeVersion": 3,
      "position": [650, 300]
    }
  ]
}
```

### Platform-Specific Posting

For **Twitter/X**, use the HTTP Request node with the Twitter API v2:

```javascript
// Code node to format for Twitter (280 char limit)
const post = .first().json;
let tweet = post.content;

if (tweet.length > 280) {
  tweet = tweet.substring(0, 277) + '...';
}

return [{ json: { text: tweet, originalId: post.id } }];
```

For **LinkedIn**, use the HTTP Request node with the LinkedIn Share API. The key is formatting the post body correctly:

```json
{
  "author": "urn:li:person:YOUR_PERSON_ID",
  "lifecycleState": "PUBLISHED",
  "specificContent": {
    "com.linkedin.ugc.ShareContent": {
      "shareCommentary": { "text": "{{ $json.content }}" },
      "shareMediaCategory": "NONE"
    }
  },
  "visibility": {
    "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
  }
}
```

---

## Workflow 3: AI-Powered Email Draft Generator

**Time saved: ~2.5 hours/week**

This is my favorite workflow. It monitors my Gmail for emails that need replies, uses Claude API to draft responses, and saves the drafts for my review.

### How It Works

A **Gmail Trigger** fires on new emails matching a specific label (I use "needs-reply"). The email content is sent to **Claude API** with a system prompt that includes my writing style and common response patterns. Claude generates a draft reply, which is saved as a Gmail draft attached to the original thread.

### Key Nodes

```json
{
  "name": "AI Email Drafter",
  "nodes": [
    {
      "parameters": {
        "pollTimes": { "item": [{ "mode": "everyMinute", "minute": 5 }] },
        "filters": { "labelIds": ["Label_needs_reply"] }
      },
      "name": "New Email",
      "type": "n8n-nodes-base.gmailTrigger",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "https://api.anthropic.com/v1/messages",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            { "name": "x-api-key", "value": "={{ $env.ANTHROPIC_API_KEY }}" },
            { "name": "anthropic-version", "value": "2023-06-01" },
            { "name": "content-type", "value": "application/json" }
          ]
        },
        "sendBody": true,
        "specifyBody": "json"
      },
      "name": "Claude Draft",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [500, 300]
    },
    {
      "parameters": {
        "resource": "draft",
        "operation": "create",
        "subject": "Re: {{ $('New Email').item.json.subject }}",
        "message": "={{ $json.content[0].text }}",
        "options": {
          "threadId": "={{ $('New Email').item.json.threadId }}"
        }
      },
      "name": "Save Draft",
      "type": "n8n-nodes-base.gmail",
      "typeVersion": 2,
      "position": [750, 300]
    }
  ]
}
```

### Why Drafts, Not Auto-Send?

I intentionally save as drafts rather than auto-sending. AI-generated emails still need a human eye for:

- **Tone** — Claude is good but not perfect at matching your voice
- **Accuracy** — Factual claims should be verified
- **Relationships** — Some emails need a more personal touch

The time savings come from having a 90%-ready draft instead of starting from a blank page. I typically spend 10-20 seconds reviewing each draft versus 3-5 minutes writing from scratch.

---

## Workflow 4: Web Scraping + Data Processing + Report Generation

**Time saved: ~2 hours/week**

Every Friday, this workflow scrapes competitor pricing pages, processes the data, generates a comparison report, and emails it to me.

### How It Works

A **Schedule Trigger** fires every Friday at 6 AM. For each competitor URL in a predefined list, an **HTTP Request** node fetches the page HTML. A **Code node** extracts pricing data using regex patterns. Finally, Claude API generates a natural-language summary report, which is sent via email.

### Key Nodes

```json
{
  "name": "Competitor Price Monitor",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [{ "triggerAtHour": 6, "triggerAtDay": 5 }]
        }
      },
      "name": "Friday 6AM",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "jsCode": "const urls = [
  { name: 'Competitor A', url: 'https://competitor-a.com/pricing' },
  { name: 'Competitor B', url: 'https://competitor-b.com/pricing' }
];
return urls.map(u => ({ json: u }));"
      },
      "name": "URL List",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [450, 300]
    },
    {
      "parameters": {
        "url": "={{ $json.url }}",
        "options": { "timeout": 10000 }
      },
      "name": "Fetch Page",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [650, 300]
    }
  ]
}
```

### Data Extraction Code Node

```javascript
const html = .first().json.data;
const name = .first().json.name;

// Extract pricing data (customize regex for each site)
const priceRegex = /$(d+(?:.d{2})?)s*(?:/s*mo|pers*month)/gi;
const prices = [];
let match;

while ((match = priceRegex.exec(html)) !== null) {
  prices.push(parseFloat(match[1]));
}

return [{
  json: {
    competitor: name,
    prices: prices,
    scrapedAt: new Date().toISOString()
  }
}];
```

### Report Generation with Claude

After collecting all competitor data, merge the results and send them to Claude for analysis:

```javascript
const allData = .all().map(item => item.json);

const prompt = "Analyze this competitor pricing data and write a brief report 
highlighting key changes, trends, and actionable insights:

"
  + JSON.stringify(allData, null, 2);

return [{ json: { prompt } }];
```

---

## Workflow 5: Telegram Bot for Task Management

**Time saved: ~1.5 hours/week**

This workflow turns Telegram into a lightweight task manager. I send tasks via Telegram, and they are automatically organized, prioritized, and synced with a Google Sheet.

### Commands

| Command | Action |
|---|---|
| `/add Buy groceries` | Adds a new task |
| `/list` | Shows all pending tasks |
| `/done 3` | Marks task #3 as complete |
| `/priority 2 high` | Sets task #2 to high priority |

### How It Works

A **Telegram Trigger** receives messages. A **Switch node** routes based on the command prefix. Each branch handles the specific operation — adding, listing, completing, or updating tasks in a Google Sheet.

### Key Nodes

```json
{
  "name": "Telegram Task Manager",
  "nodes": [
    {
      "parameters": {
        "updates": ["message"]
      },
      "name": "Telegram Trigger",
      "type": "n8n-nodes-base.telegramTrigger",
      "typeVersion": 1.1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "rules": {
          "rules": [
            { "value": "/add", "output": 0 },
            { "value": "/list", "output": 1 },
            { "value": "/done", "output": 2 },
            { "value": "/priority", "output": 3 }
          ]
        },
        "dataType": "string",
        "value1": "={{ $json.message.text.split(' ')[0] }}"
      },
      "name": "Command Router",
      "type": "n8n-nodes-base.switch",
      "typeVersion": 3,
      "position": [450, 300]
    }
  ]
}
```

### Add Task Handler

```javascript
const text = .message.text;
const taskText = text.replace(/^/adds+/, '');
const chatId = .message.chat.id;

if (!taskText) {
  return [{ json: { chatId, response: 'Usage: /add <task description>' } }];
}

const task = {
  id: Date.now(),
  text: taskText,
  status: 'pending',
  priority: 'normal',
  createdAt: new Date().toISOString(),
  chatId: chatId
};

return [{ json: { ...task, response: 'Task added: ' + taskText } }];
```

### List Tasks Handler

```javascript
const tasks = .all().map(item => item.json);
const pending = tasks.filter(t => t.status === 'pending');

if (pending.length === 0) {
  return [{ json: { response: 'No pending tasks. Use /add to create one.' } }];
}

const list = pending.map((t, i) => {
  const pri = t.priority === 'high' ? '[!]' : '   ';
  return (i + 1) + '. ' + pri + ' ' + t.text;
}).join('
');

return [{ json: { response: 'Pending tasks:

' + list } }];
```

---

## Performance Tips for n8n Workflows

After running these workflows for over a year, here are my top optimization tips:

### 1. Use Static Data for Caching

n8n's `()` persists data between executions without needing a database:

```javascript
const cache = ('global');
const cacheKey = 'lastResult_' + someId;
const cacheMaxAge = 3600000; // 1 hour

if (cache[cacheKey] && (Date.now() - cache[cacheKey].timestamp) < cacheMaxAge) {
  return [{ json: cache[cacheKey].data }];
}

// ... fetch fresh data ...
cache[cacheKey] = { data: freshData, timestamp: Date.now() };
```

### 2. Error Handling on Every API Call

Always add an error handler. API calls fail more often than you think — rate limits, network issues, expired tokens:

```javascript
try {
  const result = .first().json;
  if (result.error) throw new Error(result.error.message);
  return [{ json: result }];
} catch (err) {
  return [{ json: { error: true, message: err.message, fallback: 'Default response' } }];
}
```

### 3. Batch Operations Where Possible

Instead of making 100 individual API calls, batch them:

```javascript
const items = .all().map(item => item.json);
const batchSize = 10;
const batches = [];

for (let i = 0; i < items.length; i += batchSize) {
  batches.push(items.slice(i, i + batchSize));
}

return batches.map(batch => ({ json: { batch } }));
```

### 4. Monitor Execution Times

n8n shows execution time per node. If a workflow takes more than 30 seconds, look for:

- **Unnecessary API calls** that could be cached
- **Sequential operations** that could run in parallel (use the **Split In Batches** node)
- **Large payloads** being passed between nodes (extract only what you need)

### 5. Use Environment Variables

Never hardcode API keys or sensitive data in workflows:

```javascript
// In n8n, reference environment variables like this:
const apiKey = .ANTHROPIC_API_KEY;
const webhookUrl = .SLACK_WEBHOOK_URL;
```

Set them in your Docker Compose or `.env` file, not in the workflow JSON.

---

## Wrapping Up

These five workflows have fundamentally changed how I work. The initial setup takes a few hours each, but the compounding time savings are enormous:

| Workflow | Weekly Time Saved |
|---|---|
| Lead Management Pipeline | 3 hours |
| Social Media Scheduling | 2 hours |
| AI Email Draft Generator | 2.5 hours |
| Web Scraping + Reports | 2 hours |
| Telegram Task Manager | 1.5 hours |
| **Total** | **11 hours/week** |

That is over 500 hours per year redirected from repetitive tasks to actual creative and strategic work.

The best part? Every one of these workflows runs on a single $6/month VPS. No SaaS subscriptions, no per-execution fees, no vendor lock-in.

**Start with one workflow — whichever solves your biggest pain point — and build from there.** The JSON snippets above are ready to import into n8n and customize for your needs.

If you want to see how I combine all of these with Claude API for even more automation, check out my previous article: [Building an AI-Powered Telegram Bot with Claude API and n8n](https://dev.to/sushihey/building-an-ai-powered-telegram-bot-with-claude-api-and-n8n).

---

*[Ryosuke Matsumiya](https://dev.to/sushihey) — AI Automation Engineer. Building [OpenClaw](https://t.me/OpenClawBot), an AI-powered Telegram agent. Passionate about n8n, Claude API, and workflow automation.*
