const db = require('./db').db;

function init(rest) {

// playlists
  rest.get('/playlist/', async (req, res) => {

    const userKey = req.query.userKey;
    const user_id = req.query.userId;
    const playlist_id = req.query.playlistId;

    const playlistsQuery =
      'SELECT up.* ' +
      'FROM user_playlists up ' +
      (user_id ? 'WHERE up.user_id = $1:raw ' : '');

    const playlistQuery =
      'SELECT p.* ' +
      'FROM playlists p ' +
      'JOIN user_playlists up ON up.playlist_id = p.id ' +
      (user_id ? 'WHERE up.user_id = $1:raw ' : '') +
      (playlist_id ? 'AND p.id = $2:raw ' : '');


    await db.any(playlistsQuery, [user_id]).then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });

}

exports.init = init;
