# Krok 1: Budowanie aplikacji
FROM node:20-alpine AS builder
WORKDIR /app
COPY app/package*.json ./
RUN npm ci
COPY app/ ./
RUN npm run build

# Krok 2: Serwowanie przez Nginx
FROM nginx:alpine
# 1. Czyścimy domyślne pliki powitalne Nginxa, żeby nie mieszały
RUN rm -rf /usr/share/nginx/html/*

# 2. Kopiujemy zawartość zbudowaną przez skrypt (np. app.js)
COPY --from=builder /app/dist/ /usr/share/nginx/html/

# 3. Kopiujemy oryginalny index.html i style ze źródła (na wypadek gdyby tam leżały)
COPY app/index.html app/styles.css /usr/share/nginx/html/

# 4. Kopiujemy konfigurację serwera
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
