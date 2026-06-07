FROM node:20-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @google/gemini-cli paperclipai

# 1. Buat direktori di tingkat ROOT dan buka aksesnya secara penuh (777)
RUN mkdir -p /paperclip/instances/default/data/run-logs \
             /paperclip/instances/default/data/workspaces \
             /workspace \
    && chown -R node:node /paperclip /workspace \
    && chmod -R 777 /paperclip /workspace

# 2. Set variabel lingkungan agar Gemini CLI tahu sandbox dimatikan
ENV GEMINI_SANDBOX=false \
    NODE_ENV=production \
    HOME=/paperclip

USER node
WORKDIR /paperclip
EXPOSE 3100

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
    CMD node -e "fetch('http://localhost:3100/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# 3. Bersihkan CMD dari perintah mkdir (karena folder sudah dijamin ada dan terbuka)
CMD ["npx", "paperclipai", "run"]
