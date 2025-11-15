# ---------- Stage 1 : build (avec pnpm) ----------
FROM node:20-alpine AS build
WORKDIR /app

# Activer pnpm via corepack (Node 20+)
RUN corepack enable

# 1) Copier d'abord les fichiers de dépendances pour optimiser le cache
COPY package.json pnpm-lock.yaml ./

# 2) Installer toutes les dépendances (dev incluses pour builder)
RUN pnpm install --frozen-lockfile

# 3) Copier le reste du code de l'app
COPY . .

# 4) Build de l'application (génère .output pour ton start)
RUN pnpm build

# ---------- Stage 2 : runtime (image finale, non-root) ----------
FROM node:20-alpine AS runtime
WORKDIR /app

# Sécurité : créer un utilisateur non-root
RUN addgroup -S app && adduser -S -G app app

# Activer pnpm
RUN corepack enable

# Copier uniquement ce qui est nécessaire pour exécuter l'app
COPY package.json pnpm-lock.yaml ./

# Installer seulement les dépendances de production
RUN pnpm install --prod --frozen-lockfile

# Copier le build généré au stage précédent
COPY --from=build /app/.output ./.output

# Exécuter sous l'utilisateur non-root
USER app

# L'app écoute sur 3000 (d'après ton script dev)
EXPOSE 3000
ENV NODE_ENV=production

# Commande de démarrage (utilise ton script "start")
CMD ["pnpm", "start"]
