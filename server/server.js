// server/server.js

const express = require('express');
const next = require('next');
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const path = require('path');

const dev = process.env.NODE_ENV !== 'production';
const app = next({ dev, dir: './src' });
const handle = app.getRequestHandler();

const swaggerDocument = YAML.load(path.join(__dirname, 'swagger.yaml'));

app.prepare().then(() => {
  const server = express();

  server.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

  server.all('*', (req, res) => {
    return handle(req, res);
  });

  const PORT = process.env.PORT || 3000;
  server.listen(PORT, (err) => {
    if (err) throw err;
    console.log(`> Ready on http://localhost:${PORT}`);
  });
});
