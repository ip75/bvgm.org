

var pg = require('knex')({
  client: 'pg',
  debug: true,
  connection: {
    host     : process.env.PG_HOST || 'localhost',
    user     : process.env.PG_USER || 'goswami.ru',
    password : process.env.PG_PASSWORD || '',
    database : process.env.PG_DB || 'goswami.ru',
    charset  : 'utf8'  },
  searchPath: 'knex, public'
});


var bookshelf = require('bookshelf')(pg);

bookshelf.plugin('pagination');
bookshelf.plugin('visibility');
bookshelf.plugin('virtuals');

var location = bookshelf.Model.extend({
  tableName: 'venues',
  media: function (){
    return this.hasMany(media);
  }
});

var publisher = bookshelf.Model.extend({
  tableName: 'publishers',
  media: function (){
    return this.hasMany(media);
  }
});

var author = bookshelf.Model.extend({
  tableName: 'author',
  hidden: 'id',
  media: function (){
    return this.belongsToMany(media, 'media_author', 'author_id', 'media_id');
  }
});
exports.authors = author;



var news = bookshelf.Model.extend({
  tableName: 'news',
  hidden: 'tag_set_id',
  media: function (){
    return this.belongsToMany(media, 'news_media_objects', 'news_id', 'media_id');
  }
});
exports.news = news;

var tags = bookshelf.Model.extend({
  tableName: 'tags',
  tagset: function (){
    return this.belongsToMany(media).through(tagsmap, 'tag_id');
  }
});
exports.tags = tags;

var tagsmap = bookshelf.Model.extend({
  tableName: 'media_tag',
  tag: function () {
    return this.belongsTo(tags);
  },
  media: function () {
    return this.belongsTo(media);
  }
});

var media = bookshelf.Model.extend({
  tableName: 'media',
  hidden: ['type', 'venue_id', 'tag_set_id', 'publisher_id'],
  mediadata: function (){
    return this.hasMany(mediadata, 'media_id');
  },
  location: function () {
    return this.belongsTo(location, 'venue_id');
  },
  publisher: function () {
    return this.belongsTo(publisher, 'publisher_id');
  },
  child: function () {
    return this.belongsToMany(media, 'xref_media', 'media_id', 'linked_media_id');
  },
  parent: function () {
    return this.belongsToMany(media, 'xref_media', 'linked_media_id', 'media_id');
  },
  news: function () {
    return this.belongsToMany(news, 'news_media_objects', 'media_id', 'news_id');
  },
  tags: function () {
    return this.belongsToMany(tags).through(tagsmap, 'media_id');
  },
  author: function () {
    return this.belongsToMany(news, 'media_author', 'media_id', 'author_id');
  }
});
exports.Media = media;

var mediadata = bookshelf.Model.extend({
  tableName: 'media_data',
  media: function(){
    return this.belongsTo(media);
  }
});

exports.MediaData = mediadata;

exports.Bookshelf = bookshelf;
