FROM n8nio/n8n:1.112.3

USER root

RUN mkdir -p /data && chown node:node /data

RUN npm install -g --omit=dev n8n-nodes-mcp
RUN npm install -g --omit=dev n8n-nodes-gemini-search

USER node