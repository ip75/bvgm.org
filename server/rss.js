var model = require('./model');
var RSS = require('rss');

function init(rest) {

  rest.get('/rss', function rss(req, res) {

    var feed = new RSS({
      title: 'Е.С. Бхакти Вигьяна Госвами Махарадж',
      description: 'Аудио лекции Е.С. Бхакти Вигьяны Госвами Махараджа',
      feed_url: 'http://goswami.ru/rss',
      site_url: 'http://goswami.ru',
      image_url: 'http://goswami.ru/img/bvgm.jpg',
      docs: 'http://goswami.ru',
      managingEditor: 'admin',
      webMaster: 'Igor',
      copyright: '2018',
      language: 'ru',
      categories: ['ISKCON','Кришна','Шримад Бхагаватам','Бхагават Гита','Госвами Махарадж','лекции'],
      pubDate: Date.now(), //'May 20, 2012 04:00:00 GMT',
      ttl: '60',
      custom_namespaces: {
        'itunes': 'http://www.itunes.com/dtds/podcast-1.0.dtd'
      },
      custom_elements: [
        {'itunes:subtitle': 'Аудио лекции Е.С. Бхакти Вигьяны Госвами Махараджа'},
        {'itunes:author': 'Е.С. Бхакти Вигьяны Госвами Махараджа'},
        {'itunes:summary': 'Аудио лекции Е.С. Бхакти Вигьяны Госвами Махараджа'},
        {'itunes:owner': [
            {'itunes:name': 'Е.С. Бхакти Вигьяна Госвами Махарадж'},
            {'itunes:email': 'admin@goswami.ru'}
          ]},
        {'itunes:image': {
            _attr: {
              href: 'http://goswami.ru/img/bvgm.jpg'
            }
          }},
        {'itunes:category': [
            {_attr: {
                text: 'Religion & Spirituality'
              }},
            {'itunes:category': {
                _attr: {
                  text: 'Religion & Spirituality'
                }
              }}
          ]}
      ]
    });


    media.where('type', 'audio').query(function (qb) {
      qb.limit(100);
    }).fetchAll({
        withRelated: ['mediadata', 'location', 'tags', 'publisher', 'author']
      }).then(function (audioTracks) {
      audioTracks.forEach(function (audio) {
        feed.item({
          title: audio.title,
          description: audio.description,
          url: audio.file_uri, // link to the item
          guid: audio.jira_ref, // optional - defaults to url
          categories: ['','','',''], // optional - array of item categories
          author: audio.author.name, // optional - defaults to feed author property
          date: audio.occurrence_date, // any format that js Date can parse.
          lat: 33.417974, //optional latitude field for GeoRSS
          long: -111.933231, //optional longitude field for GeoRSS
          enclosure: {url:'...', file:'path-to-file'}, // optional enclosure
          custom_elements: [
            {'itunes:author': 'Е.С. Бхакти Вигьяна Госвами Махарадж'},
            {'itunes:subtitle': audio.title},
            {'itunes:image': {
                _attr: {
                  href: 'http://goswami.ru/img/bvgm.jpg'
                }
              }},
            {'itunes:duration': audio.duration}
          ]
        });
      });
    });

    var xml = feed.xml();
    res.send(xml);



  });
}

exports.init = init;
