const db = require('./db').db;

function init(rest) {

// admin
  rest.get('/admin/users', async (req, res) => {

    const userKey = req.query.userKey;

    const usersQuery =
      'SELECT ' +
      ' u.email, ' +
      ' u.username, ' +
      ' u.password, ' +
      ' u.last_login, ' +
      ' ud.name, ' +
      ' ud.avatar, ' +
      ' ud.spiritual_name, ' +
      ' ud.city, ' +
      ' ud.activity, ' +
      ' ud.phone, ' +
      ' ud.birth_date, ' +
      ' ud.geo_location ' +
      'FROM users u ' +
      'JOIN user_data ud ON u.id = ud.user_id ';

    await db.any(usersQuery).then(
      function (data) {
        res.send(data);
      }
    ).catch(function (e) {
      console.log(e);
    });
  });

}

exports.init = init;
