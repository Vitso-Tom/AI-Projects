# n8n Integration Roadmap

Detailed implementation guide for integrating n8n workflow automation with the AI workspace architecture.

## Vision

Create a visual, functional automation layer that orchestrates multiple AI tools (Claude, Gemini, Codex) through n8n workflows, providing both beautiful visual diagrams and working automation accessible via MCP server integration with Claude Code.

## Architecture Goal

```
┌─────────────────────────────────────────────────────────────┐
│                        Claude Code                          │
│                     (Main Orchestrator)                     │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ MCP Protocol
                             ↓
┌─────────────────────────────────────────────────────────────┐
│                    n8n Workflow Engine                      │
│                   (Visual Orchestration)                    │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│  │   Claude    │───→│   Gemini    │───→│    Codex    │   │
│  │   Create    │    │   Security  │    │  Optimize   │   │
│  └─────────────┘    └─────────────┘    └─────────────┘   │
│         │                   │                   │          │
│         └───────────────────┴───────────────────┘          │
│                             ↓                              │
│                    Aggregated Response                     │
└─────────────────────────────────────────────────────────────┘
```

## Phase 1: Docker Installation in WSL Ubuntu

### Prerequisites Check

```bash
# Verify WSL version
wsl --version

# Check Ubuntu version
lsb_release -a

# Verify system resources
free -h
df -h /

# Check if Docker is already installed
docker --version 2>/dev/null || echo "Docker not installed"
```

**Minimum Requirements:**
- WSL 2 (not WSL 1)
- Ubuntu 20.04 or later
- 4GB RAM available
- 10GB disk space free
- Internet connectivity for package downloads

### Docker Installation Steps

**Step 1: Update System Packages**
```bash
sudo apt-get update
sudo apt-get upgrade -y
```

**Step 2: Install Prerequisites**
```bash
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

**Step 3: Add Docker's Official GPG Key**
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

**Step 4: Set Up Docker Repository**
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**Step 5: Install Docker Engine**
```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

**Step 6: Configure User Permissions**
```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Apply group changes (requires logout/login or newgrp)
newgrp docker
```

**Step 7: Verify Installation**
```bash
# Check Docker version
docker --version

# Test Docker functionality
docker run hello-world

# Verify docker compose
docker compose version
```

### Docker Service Management in WSL

**Start Docker Service:**
```bash
sudo service docker start
```

**Check Docker Status:**
```bash
sudo service docker status
```

**Auto-start Docker (Optional):**
Add to `~/.bashrc`:
```bash
# Auto-start Docker if not running
if ! service docker status &>/dev/null; then
    sudo service docker start
fi
```

### Security Configuration

**Step 1: Enable Content Trust (Optional but Recommended)**
```bash
export DOCKER_CONTENT_TRUST=1
echo 'export DOCKER_CONTENT_TRUST=1' >> ~/.bashrc
```

**Step 2: Configure Resource Limits**
Create `/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
```

Restart Docker:
```bash
sudo service docker restart
```

## Phase 2: n8n Deployment

### Deployment Strategy

**Option A: Simple Docker Run (Development)**
Quick start for testing and development.

**Option B: Docker Compose (Recommended)**
Production-ready with persistent data and proper configuration.

### Option A: Simple Docker Run

WARNING: SECURITY WARNING - Change default credentials before deployment.
Replace "CHANGE_ME_INSECURE_DEFAULT" with a strong, unique password.

```bash
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=CHANGE_ME_INSECURE_DEFAULT \
  -e WEBHOOK_URL=http://localhost:5678/ \
  n8nio/n8n
```

**Access:** http://localhost:5678

### Option B: Docker Compose (Recommended)

**Step 1: Create Project Directory**
```bash
mkdir -p ~/n8n-docker
cd ~/n8n-docker
```

**Step 2: Create docker-compose.yml**

WARNING: SECURITY WARNING - Change default credentials before deployment.
Never use default passwords in production environments.

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      # Security
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD:-CHANGE_ME_INSECURE_DEFAULT}

      # Core Configuration
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/

      # Execution
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true

      # Timezone
      - GENERIC_TIMEZONE=America/New_York

      # Logging
      - N8N_LOG_LEVEL=info
      - N8N_LOG_OUTPUT=console

    volumes:
      # Persistent data
      - n8n_data:/home/node/.n8n

      # Optional: Custom nodes
      # - ./custom-nodes:/home/node/.n8n/custom

    # Resource limits (optional but recommended)
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M

volumes:
  n8n_data:
    driver: local
```

**Step 3: Create Environment File**

WARNING: SECURITY WARNING - Replace all example credentials with strong, unique passwords.
Never commit this .env file to version control. Add it to .gitignore.

```bash
cat > .env <<'EOF'
# n8n Configuration
# WARNING: Change this to a strong, unique password
N8N_PASSWORD=REPLACE_WITH_STRONG_PASSWORD_MINIMUM_16_CHARS

# Change these for production
N8N_HOST=localhost
N8N_PORT=5678
EOF
```

**Step 4: Launch n8n**
```bash
docker compose up -d
```

**Step 5: Verify Deployment**
```bash
# Check container status
docker compose ps

# View logs
docker compose logs -f n8n

# Test access
curl http://localhost:5678/healthz
```

**Access n8n:**
- URL: http://localhost:5678
- Username: admin
- Password: (value from .env file)

### n8n Management Commands

```bash
# Start n8n
docker compose up -d

# Stop n8n
docker compose down

# Restart n8n
docker compose restart

# View logs
docker compose logs -f

# Update n8n
docker compose pull
docker compose up -d

# Backup data
docker compose down
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-backup-$(date +%Y%m%d).tar.gz /data

# Restore data
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar xzf /backup/n8n-backup-YYYYMMDD.tar.gz -C /
```

## Phase 3: Build AI Orchestration Workflow

### Workflow Design

**Workflow Name:** `multi-ai-code-review`

**Trigger:** Webhook or Manual
**Steps:**
1. Receive code/task input
2. Send to Claude for initial creation/implementation
3. Send Claude output to Gemini for security review
4. Send to Codex for optimization suggestions
5. Aggregate all responses
6. Return formatted result

### Building the Workflow

**Step 1: Create New Workflow in n8n**

1. Access n8n UI (http://localhost:5678)
2. Click "New Workflow"
3. Name it "multi-ai-code-review"

**Step 2: Add Webhook Trigger**

1. Add "Webhook" node
2. Configure:
   - HTTP Method: POST
   - Path: `ai-review`
   - Response Mode: "When Last Node Finishes"
3. Test webhook URL will be: `http://localhost:5678/webhook/ai-review`

**Step 3: Add HTTP Request Nodes for Each AI**

**Node 1: Claude API Call**
```json
{
  "name": "Claude - Create",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://api.anthropic.com/v1/messages",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "anthropicApi",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "anthropic-version",
          "value": "2023-06-01"
        }
      ]
    },
    "sendBody": true,
    "bodyParameters": {
      "parameters": [
        {
          "name": "model",
          "value": "claude-sonnet-4-5-20250929"
        },
        {
          "name": "max_tokens",
          "value": "4096"
        },
        {
          "name": "messages",
          "value": "={{ [{\"role\": \"user\", \"content\": $json.task}] }}"
        }
      ]
    }
  }
}
```

**Node 2: Gemini API Call**
```json
{
  "name": "Gemini - Security Review",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent",
    "authentication": "predefinedCredentialType",
    "sendQuery": true,
    "queryParameters": {
      "parameters": [
        {
          "name": "key",
          "value": "={{ $credentials.geminiApiKey }}"
        }
      ]
    },
    "sendBody": true,
    "bodyParameters": {
      "parameters": [
        {
          "name": "contents",
          "value": "={{ [{\"parts\": [{\"text\": \"Security review: \" + $node[\"Claude - Create\"].json.content[0].text}]}] }}"
        }
      ]
    }
  }
}
```

**Node 3: OpenAI/Codex API Call**
```json
{
  "name": "Codex - Optimize",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://api.openai.com/v1/chat/completions",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "openAiApi",
    "sendBody": true,
    "bodyParameters": {
      "parameters": [
        {
          "name": "model",
          "value": "gpt-4"
        },
        {
          "name": "messages",
          "value": "={{ [{\"role\": \"user\", \"content\": \"Optimize this code: \" + $node[\"Claude - Create\"].json.content[0].text}] }}"
        }
      ]
    }
  }
}
```

**Step 4: Add Aggregation Node**

Use "Code" node to combine results:
```javascript
const claudeResponse = $node["Claude - Create"].json.content[0].text;
const geminiResponse = $node["Gemini - Security Review"].json.candidates[0].content.parts[0].text;
const codexResponse = $node["Codex - Optimize"].json.choices[0].message.content;

return {
  json: {
    original_task: $json.task,
    claude_implementation: claudeResponse,
    gemini_security_review: geminiResponse,
    codex_optimization: codexResponse,
    timestamp: new Date().toISOString(),
    workflow: "multi-ai-code-review"
  }
};
```

**Step 5: Add Response Node**

Configure webhook response with aggregated data.

### API Credentials Setup

**Required API Keys:**
1. Anthropic API Key (Claude)
2. Google AI API Key (Gemini)
3. OpenAI API Key (Codex)

**Add Credentials in n8n:**
1. Settings → Credentials
2. Add each API credential
3. Reference in HTTP Request nodes

### Testing the Workflow

**Test Payload:**
```bash
curl -X POST http://localhost:5678/webhook/ai-review \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Write a Python function to validate email addresses with regex"
  }'
```

**Expected Response:**
```json
{
  "original_task": "Write a Python function...",
  "claude_implementation": "...",
  "gemini_security_review": "...",
  "codex_optimization": "...",
  "timestamp": "2025-11-20T...",
  "workflow": "multi-ai-code-review"
}
```

## Phase 4: MCP Server Configuration

### Understanding MCP Integration

MCP (Model Context Protocol) allows Claude Code to communicate with external tools and services. We'll configure n8n as an MCP server.

### Architecture Pattern

```
Claude Code → MCP Client → MCP Server (n8n) → AI Workflows
```

### Implementation Options

**Option A: n8n Webhook MCP Server (Simpler)**
Create a lightweight MCP server that proxies to n8n webhooks.

**Option B: n8n API MCP Server (Full-featured)**
Use n8n's API for full workflow management and monitoring.

### Option A: n8n Webhook MCP Server

**Step 1: Create MCP Server Script**

Create `~/ai-workspace/n8n-mcp-server.js`:
```javascript
#!/usr/bin/env node

/**
 * MCP Server for n8n Integration
 * Allows Claude Code to trigger n8n workflows via MCP protocol
 */

const http = require('http');
const https = require('https');

const N8N_BASE_URL = process.env.N8N_BASE_URL || 'http://localhost:5678';
const MCP_PORT = process.env.MCP_PORT || 3000;

// Available workflows
const WORKFLOWS = {
  'multi-ai-review': {
    webhook: '/webhook/ai-review',
    description: 'Multi-AI code review (Claude → Gemini → Codex)'
  },
  // Add more workflows as you build them
};

// MCP Protocol Handler
const server = http.createServer(async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.method !== 'POST') {
    res.writeHead(405, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Method not allowed' }));
    return;
  }

  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', async () => {
    try {
      const request = JSON.parse(body);
      const { workflow, payload } = request;

      if (!WORKFLOWS[workflow]) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Workflow not found' }));
        return;
      }

      // Proxy to n8n webhook
      const n8nUrl = `${N8N_BASE_URL}${WORKFLOWS[workflow].webhook}`;
      const response = await forwardToN8n(n8nUrl, payload);

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(response));

    } catch (error) {
      console.error('Error:', error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: error.message }));
    }
  });
});

function forwardToN8n(url, payload) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(payload);
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    };

    const req = http.request(url, options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch {
          resolve({ raw: body });
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

server.listen(MCP_PORT, () => {
  console.log(`n8n MCP Server running on port ${MCP_PORT}`);
  console.log('Available workflows:', Object.keys(WORKFLOWS));
});
```

**Step 2: Make Script Executable**
```bash
chmod +x ~/ai-workspace/n8n-mcp-server.js
```

**Step 3: Test MCP Server**
```bash
# Start server
node ~/ai-workspace/n8n-mcp-server.js

# Test in another terminal
curl -X POST http://localhost:3000 \
  -H "Content-Type: application/json" \
  -d '{
    "workflow": "multi-ai-review",
    "payload": {
      "task": "Test task"
    }
  }'
```

### Option B: n8n API MCP Server

**Coming Soon:** Full implementation using n8n REST API for workflow management, execution history, and monitoring.

### Configuring Claude Code MCP

**Step 1: Update Claude Code MCP Configuration**

Location: `~/.config/claude-code/mcp.json` (or platform-specific)

```json
{
  "mcpServers": {
    "n8n-workflows": {
      "command": "node",
      "args": ["/home/temlock/ai-workspace/n8n-mcp-server.js"],
      "env": {
        "N8N_BASE_URL": "http://localhost:5678",
        "MCP_PORT": "3000"
      }
    }
  }
}
```

**Step 2: Restart Claude Code**

The MCP server will auto-start when Claude Code launches.

**Step 3: Test Integration from Claude Code**

Ask Claude Code to use the n8n workflow:
```
"Use the n8n multi-ai-review workflow to analyze this code..."
```

## Phase 5: Visual Representation

### Workflow Canvas Best Practices

**Layout Strategy:**
```
[Webhook Trigger]
       ↓
[Parse Input] ────→ [Error Handler]
       ↓
[Claude Create]
       ↓
[Gemini Security] ──→ [Store Review]
       ↓                     ↓
[Codex Optimize] ──→ [Store Results]
       ↓                     ↓
[Aggregate] ←────────────────┘
       ↓
[Format Response]
       ↓
[Return to Webhook]
```

**Visual Enhancements:**
1. Use sticky notes for documentation
2. Color-code nodes by function (input=blue, AI=green, output=purple)
3. Add descriptive node names
4. Use workflow descriptions
5. Group related nodes with frames

### Export and Documentation

**Export Workflow as JSON:**
1. Workflow Settings → Download
2. Save as `workflows/multi-ai-review.json`
3. Version control the workflow

**Screenshot for Documentation:**
1. Zoom to fit all nodes
2. Screenshot the canvas
3. Add to project README or documentation

## Security Considerations

### Healthcare/Regulated Environment Compliance

**Data Handling:**
- Never process PHI/PII through public AI APIs
- Use this architecture for non-sensitive consulting work only
- For client work: Deploy n8n in client's environment
- Consider using private AI model deployments

**Access Control:**
- Enable n8n basic authentication (already configured)
- Use strong passwords (change default!)
- Consider adding nginx reverse proxy with SSL
- Restrict Docker network exposure

**API Key Management:**
- Store API keys in environment variables
- Never commit keys to git
- Use .env files (add to .gitignore)
- Rotate keys regularly
- Consider using vault solutions for production

**Audit Trail:**
- n8n execution history provides audit logs
- Enable execution data saving
- Regular backup of n8n data volume
- Monitor for unusual activity

**Network Security:**
```bash
# Limit n8n to localhost only
docker compose down
# Edit docker-compose.yml:
# ports:
#   - "127.0.0.1:5678:5678"  # Only accessible from localhost
docker compose up -d
```

### Production Hardening Checklist

- [ ] Change default n8n password
- [ ] Enable HTTPS/SSL (nginx reverse proxy)
- [ ] Restrict Docker network access
- [ ] Configure firewall rules (ufw)
- [ ] Enable Docker content trust
- [ ] Set up regular backups
- [ ] Configure log rotation
- [ ] Implement monitoring/alerting
- [ ] Document incident response procedures
- [ ] Regular security updates

## Troubleshooting

### Docker Issues

**Problem: Docker daemon not running**
```bash
# Solution
sudo service docker start
```

**Problem: Permission denied accessing Docker**
```bash
# Solution
sudo usermod -aG docker $USER
newgrp docker
```

**Problem: Port 5678 already in use**
```bash
# Find what's using the port
sudo lsof -i :5678

# Change port in docker-compose.yml
# ports:
#   - "5679:5678"  # Use different host port
```

### n8n Issues

**Problem: n8n container won't start**
```bash
# Check logs
docker compose logs n8n

# Common fixes:
# 1. Clear volumes and restart
docker compose down -v
docker compose up -d

# 2. Check disk space
df -h
```

**Problem: Workflows not executing**
```bash
# Check execution logs in n8n UI
# Settings → Executions → View details

# Verify API credentials
# Settings → Credentials → Test connection
```

**Problem: Webhook not responding**
```bash
# Test webhook directly
curl -v http://localhost:5678/webhook/test

# Check n8n logs
docker compose logs -f n8n
```

### MCP Integration Issues

**Problem: Claude Code can't connect to MCP server**
```bash
# Verify MCP server is running
ps aux | grep n8n-mcp-server

# Check MCP server logs
node ~/ai-workspace/n8n-mcp-server.js

# Verify configuration
cat ~/.config/claude-code/mcp.json
```

**Problem: MCP server can't reach n8n**
```bash
# Test connectivity
curl http://localhost:5678/healthz

# Check Docker network
docker network ls
docker network inspect bridge
```

### API Issues

**Problem: AI API calls failing**
```bash
# Test API keys directly
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-sonnet-20240229","max_tokens":1024,"messages":[{"role":"user","content":"test"}]}'

# Check rate limits
# Review API provider documentation
```

## Success Metrics

### Phase Completion Criteria

**Phase 1: Docker Installation**
- [ ] Docker daemon running
- [ ] `docker run hello-world` succeeds
- [ ] User in docker group (no sudo required)
- [ ] docker compose available

**Phase 2: n8n Deployment**
- [ ] n8n accessible at http://localhost:5678
- [ ] Can log in with credentials
- [ ] Create and save test workflow
- [ ] Webhook trigger works

**Phase 3: AI Workflow**
- [ ] Workflow receives webhook requests
- [ ] Claude API integration works
- [ ] Gemini API integration works
- [ ] Codex API integration works
- [ ] Aggregation returns combined results

**Phase 4: MCP Integration**
- [ ] MCP server starts successfully
- [ ] Claude Code recognizes MCP server
- [ ] Can trigger workflows from Claude Code
- [ ] Results return to Claude Code

**Phase 5: Visual Representation**
- [ ] Workflow visually clear and organized
- [ ] Documentation complete
- [ ] Screenshot captured
- [ ] JSON export saved

## Next Steps After Completion

### Workflow Extensions

1. **Error Handling Workflow**: Dedicated workflow for debugging failed executions
2. **Batch Processing**: Process multiple files/tasks in parallel
3. **Notification Integration**: Slack/email notifications for workflow completions
4. **Version Comparison**: Compare outputs from different AI models
5. **Cost Tracking**: Monitor API usage and costs per workflow

### Advanced Integrations

1. **GitHub Integration**: Trigger workflows on pull requests
2. **Slack Bot**: Invoke workflows from Slack commands
3. **Scheduled Workflows**: Cron-based automation tasks
4. **Database Integration**: Store results in PostgreSQL/MongoDB
5. **Custom Nodes**: Build n8n nodes for specialized tasks

### Documentation Improvements

1. Record video walkthrough of workflow creation
2. Create workflow templates for common patterns
3. Document troubleshooting solutions as they arise
4. Build internal knowledge base for consulting clients

## References

### Official Documentation

- [Docker on WSL](https://docs.docker.com/desktop/wsl/)
- [n8n Documentation](https://docs.n8n.io/)
- [n8n Docker Setup](https://docs.n8n.io/hosting/installation/docker/)
- [Claude API Documentation](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)

### Community Resources

- [n8n Community Forum](https://community.n8n.io/)
- [n8n Workflow Templates](https://n8n.io/workflows/)
- [Docker WSL Best Practices](https://www.docker.com/blog/docker-desktop-wsl-2-best-practices/)

### Security References

- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [n8n Security Documentation](https://docs.n8n.io/hosting/security/)
- [API Key Management Best Practices](https://owasp.org/www-community/vulnerabilities/Storing_Secrets)

---

**Document Version:** 1.0.0
**Last Updated:** 2025-11-20
**Maintained By:** Tom Vitso + Claude Code
**Status:** Ready for implementation
