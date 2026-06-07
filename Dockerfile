# ==========================================
# 1. TAHAP BASE (Sistem Dasar)
# ==========================================
FROM node:lts-trixie-slim AS base
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git wget ripgrep python3 \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable

# ==========================================
# 2. TAHAP DEPS (Unduh Source Code & Dependensi)
# ==========================================
FROM base AS deps
WORKDIR /app
RUN git clone --depth 1 https://github.com/paperclipai/paperclip.git . \
  && pnpm install --frozen-lockfile

# ==========================================
# 3. TAHAP BUILD (Kompilasi Aplikasi)
# ==========================================
FROM base AS build
WORKDIR /app
COPY --from=deps /app /app
RUN pnpm --filter @paperclipai/ui build \
  && pnpm --filter @paperclipai/plugin-sdk build \
  && pnpm --filter @paperclipai/server build \
  && test -f server/dist/index.js

# ==========================================
# 4. TAHAP PRODUCTION (Hasil Akhir & Gemini CLI)
# ==========================================
FROM base AS production
WORKDIR /app
COPY --from=build /app /app

# Memasang tools produksi sekaligus Gemini CLI lewat NPM (Solusi Error 404)
RUN apt-get update \
  && apt-get install -y --no-install-recommends openssh-client jq gosu \
  && npm install -g @google/gemini-cli \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /paperclip

# Konfigurasi skrip eksekusi bawaan Paperclip
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Pengaturan Environment Variables Sistem
ENV NODE_ENV=production \
  HOME=/paperclip \
  HOST=0.0.0.0 \
  PORT=3100 \
  SERVE_UI=true \
  PAPERCLIP_HOME=/paperclip \
  PAPERCLIP_INSTANCE_ID=default \
  PAPERCLIP_CONFIG=/paperclip/instances/default/config.json \
  PAPERCLIP_DEPLOYMENT_MODE=authenticated \
  PAPERCLIP_DEPLOYMENT_EXPOSURE=public

# Membuka port jaringan aplikasi
EXPOSE 3100

# Menjalankan aplikasi utama
CMD ["start.sh"]
