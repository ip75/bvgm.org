const db = require('./db').db;

function init(rest) {

  rest.get('/carousel', async (req, res) => {

    const userKey = req.query.userKey;

    await db.any('SELECT ID, image_url imageUrl, target_url targetUrl, position "order", visible FROM carousel ORDER BY position ASC').then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });

  rest.post('/carousel/add', async (req, res) => {

    const userKey = req.body.userKey;
    const image_url = req.body.imageUrl;
    const target_url = req.body.targetUrl;
    const position = req.body.position;
    const visible = req.body.visible;

    const sql = 'INSERT INTO carousel (image_url, target_url, position, visible) ' +
      'VALUES ($1, $2, $3:raw, $4)  RETURNING id';
    await db.one(sql, [image_url, target_url, position, visible]).then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
      res.send(e);
    });
  });


  rest.post('/carousel/remove', async (req, res) => {

    const userKey = req.body.userKey;
    const id = req.body.id;

    const sql = 'DELETE FROM carousel where id = $1:raw';
    await db.result(sql, [id]).then(
      result => {
        console.log(result.rowCount);
        res.send({count: result.rowCount});
      }
    ).catch(function (e) {
      console.log(e);
      res.send(e);
    });
  });


  rest.get('/top/news', async (req, res) => {

    const userKey = req.query.userKey;
    const direction = req.query.direction ? req.query.direction : 'DESC';
    const count = req.query.count ? req.query.count : 8;

    const newsQuery =
      'SELECT ' +
      ' n.ID, ' +
      ' n.image_url imageUrl, ' +
      ' n.title, ' +
      ' n.teaser annotation, ' +
      ' n.body, ' +
      ' n.news_date "date", ' +
      ' m.file_url targetUrl, ' +
      ' m.type ' +
      'FROM news n ' +
      'JOIN media m ON m.id = n.media_id ' +
      'ORDER BY n.news_date $1:raw ' +
      'LIMIT $2:raw ';

    await db.any(newsQuery, [direction, count]).then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });

}

exports.init = init;

