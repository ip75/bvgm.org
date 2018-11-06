var express = require('express'),
  rest = express(),
  auth = require('./auth'),
  catalog = require('./catalog'),
  news = require('./news'),
  admin = require('./admin'),
  playlists = require('./playlists'),
  dict = require('./dictionaries');


rest.locals.title = "REST goswami.ru";
rest.locals.strftime = require('strftime');
rest.locals.email = "admin@goswami.ru";

function start() {

  rest.use(require('morgan')('dev'));
  rest.use(require('cookie-parser')());
  rest.use(require('body-parser').urlencoded({ extended: true }));
  rest.use(require('express-session')({ secret: 'keyboard cat', resave: false, saveUninitialized: false }));

  auth.init(rest);

  catalog.init(rest);
  news.init(rest);
  dict.init(rest);
  admin.init(rest);
  playlists.init(rest);

  rest.listen(8888);
  console.log("Server has started.");
}

exports.start = start;
