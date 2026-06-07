FROM node:20-slim

# Install dependencies & Gemini CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @google/gemini-cli paperclipai

# Buat direktori dengan permissions yang benar SEBELUM switch user
# node:20-slim sudah punya user 'node' (uid 1000)
RUN mkdir -p /paperclip/instances/default/data/run-logs \
             /paperclip/instances/default/data/workspaces \
             /workspace \
    && chown -R node:node /paperclip /workspace

# Switch ke user non-root
USER node

WORKDIR /paperclip
EXPOSE 3100

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
    CMD node -e "fetch('http://localhost:3100/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["sh", "-c", \
    "mkdir -p /paperclip/instances/default/data/run-logs && \
     npx paperclipai server start --port 3100 --host 0.0.0.0"]
