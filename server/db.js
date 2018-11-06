const Promise = require('bluebird');
const pgpOptions = {
  promiseLib: Promise,
  query(e) {
    console.log('QUERY:', e.query);
  }
};

const pgp = require('pg-promise')(pgpOptions);

// Creating a new database instance from the connection details:
const db = pgp({
  user: 'goswami.ru',
  host: 'localhost',
  database: 'goswami.ru',
  password: ''
});

// Exporting the database object for shared use:
exports.db = db;
