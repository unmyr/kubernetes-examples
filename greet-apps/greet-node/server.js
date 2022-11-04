const express = require('express');
const log4js = require('log4js');

const logger = log4js.getLogger();
logger.level = 'debug';

const port = 8080;

const app = express();
app.use(express.json());
app.use(
  express.urlencoded({
    extended: true,
  })
);

app.get('/api/greet/:name', (req, res) => {
  logger.debug(`GET: /api/greet/${req.params.name}`);
  res.json({ message: `Hello ${req.params.name}!` });
});

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`);
});

module.exports = app;
