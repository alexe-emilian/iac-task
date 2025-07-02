# ─ Build Stage ──────────────────────────────────────────
FROM node:20-alpine AS build
WORKDIR /usr/src/app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev
COPY src ./src

# ─ Runtime Stage ───────────────────────────────────────
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /usr/src/app
COPY --from=build /usr/src/app .
EXPOSE 3000
ENTRYPOINT ["node", "src/app.js"]