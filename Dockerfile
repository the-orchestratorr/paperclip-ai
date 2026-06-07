FROM node:20-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @google/gemini-cli paperclipai

# Buat direktori dan set permissions sebelum switch user
RUN mkdir -p /paperclip/instances/default/data/run-logs \
             /paperclip/instances/default/data/workspaces \
             /workspace \
    && chown -R node:node /paperclip /workspace

USER node
WORKDIR /paperclip
EXPOSE 3100

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
    CMD node -e "fetch('http://localhost:3100/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# ✅ CMD yang benar: "run" bukan "server start"
CMD ["sh", "-c", \
    "mkdir -p /paperclip/instances/default/data/run-logs && \
     npx paperclipai run"]
