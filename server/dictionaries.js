const db = require('./db').db;


function init(rest) {

  rest.get('/dictionaries/authors', async (req, res) => {

    const userKey = req.query.userKey;

    await db.any('SELECT * FROM authors').then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });

  rest.get('/dictionaries/categories', async (req, res) => {

    const userKey = req.query.userKey;

    await db.any('SELECT * FROM categories').then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });

  rest.get('/dictionaries/locations', async (req, res) => {

    const userKey = req.query.userKey;

    await db.any('SELECT * FROM locations').then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });


  rest.get('/dictionaries/publishers', async (req, res) => {

    const userKey = req.query.userKey;

    await db.any('SELECT * FROM publishers').then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });

  rest.get('/dictionaries/scriptures', async (req, res) => {

    const userKey = req.query.userKey;

    await db.any('SELECT * FROM scriptures').then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });

  rest.get('/dictionaries/tags', async (req, res) => {

    const userKey = req.query.userKey;

    await db.any('SELECT * FROM tags').then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });

}

exports.init = init;
