const db = require('./db').db;


function init(rest) {

// collections
  rest.get('/catalogue/collections', async (req, res) => {

    const userKey = req.query.userKey;
    const direction = req.query.direction ? req.query.direction : 'DESC';
    const pagesize = req.query.pagesize ? req.query.pagesize : 100;
    const offset = req.query.pagenum * pagesize ? req.query.pagenum * pagesize : 0;
    const category = req.query.categoryId;
    const yearBegin = req.query.yearBegin;
    const yearEnd = req.query.yearEnd;
    const tags = req.query.tags;
    const searchText = req.query.searchText;

    const result =
      ' id, ' +
      ' img_url imageUrl, ' +
      ' title, ' +
      ' body, ' +
      ' date_part(\'year\', occurrence_date) \"year\" ';

    const filter =
      'FROM media ' +
      'WHERE type = $1 ' +
      (yearBegin ? 'AND date_part(\'year\', occurrence_date) >= $2 ' : '') +
      (yearEnd ? 'AND date_part(\'year\', occurrence_date) <= $3 ' : '') +
      (category ? 'AND m.category_id = $4 ' : '') +
      'AND visible = true ';

    const tail =
      'ORDER BY occurrence_date $5:raw ' +
      (pagesize ? 'LIMIT $6:raw ' : '') +
      (offset ? 'OFFSET $7:raw ' : '');

    const collectionsQuery = 'SELECT ' + result + filter + tail;
    const params = ['collection', yearBegin, yearEnd, category, direction, pagesize, offset];


    await db.one('select count(*) ' + filter, params, c => +c.count).then(
      count => {
        db.any(collectionsQuery, params).then(
          function (data) {
            res.send({total: count, list: data});
          }
        ).catch(function (e) {
          console.log(e);
        });
      });
  });

// add album / collection / disk
  rest.post('/catalogue/collections/add', async (req, res) => {

  });

  rest.post('/catalogue/collections/update', async (req, res) => {

  });

// remove album / collection / disk   - when delete collection, audio will be unlinked by xref_media
  rest.post('/catalogue/collections/remove', async (req, res) => {

  });

// add audio to collection. add link to xref_media
  rest.post('/catalogue/collections/audio/add', async (req, res) => {

  });

  rest.post('/catalogue/collections/audio/update', async (req, res) => {

  });

// remove audio from collection. remove link from xref_media
  rest.post('/catalogue/collections/audio/remove', async (req, res) => {

  });


// audio
  rest.get('/catalogue/audio', async (req, res) => {

    const userKey = req.query.userKey;
    const pagenum = req.query.pagenum;
    const pagesize = req.query.pagesize;
    const searchText = req.query.searchText;
    const direction = req.query.direction ? req.query.direction : 'DESC';
    const categoryId = req.query.categoryId;
    const scriptureId = req.query.scriptureId;
    const canto = req.query.canto;
    const chapter = req.query.chapter;
    const verse = req.query.verse;
    const dateBegin = req.query.dateBegin;
    const dateEnd = req.query.dateEnd;
    const locationId = req.query.locationId;
    const tag = req.query.tag;
    const authorId = req.query.authorId;
    const offset = pagesize * pagenum;

    const result =
      ' m.id, ' +
      ' m.img_url imageUrl, ' +
      ' m.title, ' +
      ' c.name categoryName, ' +
      ' (SELECT json_agg(a.name) FROM authors a JOIN media_authors ma ON ma.author_id = a.id AND ma.media_id = m.id) author, ' +
      ' l.name "location", ' +
      ' m.body, ' +
      ' m.occurrence_date "date", ' +
      ' m.duration, ' +
      ' m.file_url fileUrl, ' +
      ' (SELECT COUNT(*)::INT::BOOLEAN FROM media_data WHERE data_type = \'video\' AND media_id = m.id) hasVideo ';

    const filter =
      'FROM media m ' +
      'LEFT JOIN categories c ON c.id = m.category_id ' +
      'LEFT JOIN locations l ON l.id = m.location_id ' +
      'WHERE m.type = $1 ' +
      (dateBegin ? 'AND m.occurrence_date >= $2 ' : '') +
      (dateEnd ? 'AND m.occurrence_date <= $3 ' : '') +
      (categoryId ? 'AND m.category_id = $4 ' : '') +
      (scriptureId ? 'AND m.scripture_id = $5 ' : '') +
      (canto ? 'AND m.canto = $6 ' : '') +
      (chapter ? 'AND m.chapter = $7 ' : '') +
      (verse ? 'AND m.verse = $8 ' : '') +
      (locationId ? 'AND m.location_id = $9 ' : '') +
      (authorId ? 'AND $10:raw in (SELECT a.id FROM authors a JOIN media_authors ma ON ma.author_id = a.id AND ma.media_id = m.id) ' : '') +
      'AND m.visible = true ';

    const tail =
      'ORDER BY m.occurrence_date $11:raw ' +
      (pagesize ? 'LIMIT $12:raw ' : '') +
      (offset ? 'OFFSET $13:raw ' : '');

    const audioQuery = 'SELECT ' + result + filter + tail;

    const params = ['audio', dateBegin, dateEnd, categoryId, scriptureId, canto, chapter, verse, locationId, authorId, direction, pagesize, offset]; //req.query.direction,

    await db.one('select count(*) ' + filter, params, c => +c.count).then(
      count => {
        db.any(audioQuery, params).then(
          function (data) {
            res.send({total: count, list: data});
          }
        ).catch(function (e) {
          console.log(e);
        });
      });
  });

  rest.get('/catalogue/articles', async (req, res) => {

    const userKey = req.query.userKey;
    const pagenum = req.query.pagenum;
    const pagesize = req.query.pagesize;
    const searchText = req.query.searchText;
    const direction = req.query.direction ? req.query.direction : 'DESC';
    const dateBegin = req.query.dateBegin;
    const dateEnd = req.query.dateEnd;
    const offset = pagenum * pagesize;

    const result =
      ' m.id, ' +
      ' m.img_url, ' +
      ' m.title, ' +
      ' m.body, ' +
      ' m.occurrence_date ';

    const filter =
      'FROM media m ' +
      'WHERE m.type = $1 ' +
      (dateBegin ? 'AND m.occurrence_date >= $2 ' : '') +
      (dateEnd ? 'AND m.occurrence_date <= $3 ' : '') +
      'AND m.visible = true ';

    const tail =
      'ORDER BY m.occurrence_date $4:raw ' +
      (pagesize ? 'LIMIT $5:raw ' : '') +
      (offset ? 'OFFSET $6:raw ' : '');

    const articlesQuery = 'SELECT ' + result + filter + tail;
    const params = ['article', dateBegin, dateEnd, direction, pagesize, offset]; //req.query.direction,

    await db.one('select count(*) ' + filter, params, c => +c.count).then(
      count => {
        db.any(articlesQuery, params).then(
          function (data) {
            res.send({total: count, list: data});
          }
        ).catch(function (e) {
          console.log(e);
        });
      });
  });
}

exports.init = init;
