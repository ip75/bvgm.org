const db = require('./db').db;
const crypto = require('crypto');
const request = require('request');
const bodyParser = require('body-parser');
const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const enshure = require('connect-ensure-login');

const hash_method = 'sha256';
const hash_key = 'eofbnredfk23r';

const common_user_fields =
  '  u.id,' +
  '  u.email,' +
  '  u.username,' +
  '  u.password,' +
  '  u.last_login,' +
  '  ud.name,' +
  '  ud.avatar,' +
  '  ud.spiritual_name,' +
  '  ud.city,' +
  '  ud.activity,' +
  '  ud.phone,' +
  '  ud.birth_date,' +
  '  ud.geo_location';


passport.use(new LocalStrategy({
  usernameField: 'username',
  passwordField: 'password'
}, async (username, password, done) => {

  const checkCredentialsQuery =
    'SELECT ' + common_user_fields +
    ' FROM users u ' +
    '  JOIN user_data ud ON u.id = ud.user_id ' +
    'WHERE ' +
    '  u.username = $1 ' +
    '  and u.password = $2';

  const hash = crypto.createHmac(hash_method, hash_key).update(password).digest('hex');

  await db.any(checkCredentialsQuery, [username, hash]).then(
    function (data) {
      if (data)
        return done(null, data[0]);
      else
        return done(null, false);
    }
  ).catch(function (e) {
    console.log(e);
    done(e);
  });
}));


passport.serializeUser(async (user, cb) => {
  cb(null, user.id);
});

passport.deserializeUser(async (id, cb) => {

  const userData =
    'SELECT ' + common_user_fields +
    ' FROM users u ' +
    '  JOIN user_data ud ON u.id = ud.user_id ' +
    'WHERE ' +
    '  u.id = $1';

  await db.any(userData, [id]).then(
    function (data) {
      cb(null, data);
    }).catch(function (e) {
    console.log(e);
    cb(e);
  });
});


function init(rest) {

  rest.use(passport.initialize());
  rest.use(passport.session());
  rest.use(bodyParser.json());

  rest.get('/auth/login', async (req, res) => {
    res.send('Make a POST method to authenticate');
  });

  rest.get('/auth/profile',
    enshure.ensureLoggedIn('/auth/login'),
    async (req, res) => {
      res.send(req.user);
    });


  rest.post('/auth/login',
    passport.authenticate('local', {
      successReturnToOrRedirect: '/auth/profile',
      successRedirect: '/auth/profile',
      failureRedirect: '/auth/login',
      failureFlash: false
    }),
    // If this function gets called, authentication was successful.
    // `req.user` contains the authenticated user.
    async (req, res) => {

      res.send(req.user);

      /*

        // insert into user_tokens data of login
        const usersQuery =
          'SELECT ' +
          ' u.id, ' +
          ' u.username, ' +
          ' u.password ' +
          'FROM users u ' +
          'JOIN user_tokens ut ON u.id = ut.user_id ';

        await db.any(usersQuery).then(
          function (data) {
            res.send(data);
            res.redirect('/');
          }
        ).catch(function (e) {
          console.log(e);
        });
      */

    });


  rest.get('/auth/logout', async (req, res) => {
    req.logout();
    res.send('Logged out');
  });

  rest.get('/auth/users',
    enshure.ensureLoggedIn('/auth/login'),
    async (req, res) => {

      let users_query =
        'SELECT ' + common_user_fields +
        ' FROM users u ' +
        '  JOIN user_data ud ON u.id = ud.user_id';

      if (req.query.id) {
        users_query += ' WHERE u.id = $1';
      }

      await db.any(users_query, [req.query.id]).then(
        function (data) {
          res.send(data);
        }
      ).catch(function (e) {
        console.log(e);
      });
    });

  rest.get('/auth/roles',
    enshure.ensureLoggedIn('/auth/login'),
    async (req, res) => {

      const roles_query =
        'SELECT r.id, r.name, r.description ' +
        ' FROM roles r ';

      await db.any(roles_query).then(
        function (data) {
          res.send(data);
        }
      ).catch(function (e) {
        console.log(e);
      });
    });


  rest.get('/auth/login', async (req, res) => {
    res.send('Make a POST method to login user');
  });


  rest.post('/auth/register',
    enshure.ensureLoggedIn('/auth/login'),
    async (req, res) => {

      const email = req.body.email;
      const username = req.body.email;
      const password = req.body.password;
      const password_hash = crypto.createHmac(hash_method, hash_key).update(password).digest('hex');


      const name = req.body.name;
      const avatar = req.body.avatar;
      const spiritual_name = req.body.spiritual_name;
      const activity = req.body.activity;
      const phone = req.body.phone;
      const birth_date = req.body.birth_date;
      const sex = req.body.gender === 'female';
      const email_subscribe = req.body.email_subscribe;
      const location = req.body.location;
      let geo_position = getGeoLocatiion(location);


      await db.tx(t => {
        return t.one('INSERT INTO ' +
          '     users(email, username, password, logins) ' +
          '     VALUES ($1, $2, $3, $4:raw) RETURNING id',
          [email, username, password_hash, 0])
          .then(user => {

            return t.one('INSERT INTO user_data(user_id, name, avatar, spiritual_name, city, activity, phone, birth_date, sex, email_subscriber, geo_location, rank) ' +
              ' VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 0) RETURNING id',
              [user.id, name, avatar, spiritual_name, location, activity, phone, birth_date, sex, email_subscribe, geo_position])
          });
      }).catch(error => {
        res.send(error);
      })
        .then(result => {
        res.send(result);
      });

    });


  function getGeoLocatiion(address) {

    request.get('http://maps.google.com/maps/api/geocode/json?address=' + encodeURI(address))
      .on('response', (response) => {

        if (response.statusCode === 200) {
          response.on('data', (data) => {
            const body = JSON.parse(data);
            if (body.status === 'OK') {
              return body.results[0].geometry.location.lat + ', ' + body.results[0].geometry.location.lng;
            }
            else {
              console.log('geo data failure status: ' + JSON.stringify(body));
            }
          })
            .on('error', (error) => {
              console.log('Error while retrieving geo location of ' + location + error);
            });
        }
        else {
          console.log('Error while retrieving geo location of ' + location + ' response: ' + response);
        }
      });
  }
}



exports.init = init;
