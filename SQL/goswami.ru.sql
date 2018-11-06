-- to update schema delete old tables


DROP TABLE IF EXISTS
          locations,
          authors,
          categories,
          carousel,
          scriptures,
          tags,
          publishers,
          media,
          media_tags,
          xref_media,
          media_authors,
          search_words,
          news_media_objects,
          collection_media_sequence,
          news_media,
          user_playlists,
          playlists,
          news,
          settings CASCADE;

--CREATE ROLE "goswami.ru";
--ALTER DATABASE "goswami.ru" OWNER TO "goswami.ru";
--ALTER ROLE "goswami.ru" LOGIN PASSWORD NULL;
--GRANT ALL ON DATABASE "goswami.ru" TO "goswami.ru";

-- СИСТЕМНЫЕ ТАБЛИЦЫ
CREATE TABLE IF NOT EXISTS settings (
    key              character varying(255),
    value            character varying(255)
);
COMMENT ON TABLE settings IS 'Настройки общие';

INSERT INTO settings (key, value) VALUES ('version', '2.0.0');

-- СПРАВОЧНИК ГОРОДОВ / МЕСТ ГДЕ ГУРУ МАХАРАДЖ И ЕГО УЧЕНИКИ ДАЮТ ЛЕКЦИИ
CREATE TABLE IF NOT EXISTS locations (
    ID               serial PRIMARY KEY,
    "name"           character varying(255)
);
COMMENT ON TABLE locations IS 'Справочник городов где читались лекции, семинары и т.д.';


-- СПРАВОЧНИК АВТОРОВ
CREATE TABLE IF NOT EXISTS authors (
    ID               serial PRIMARY KEY,
    "name"           character varying(255)
);

CREATE TABLE IF NOT EXISTS tags (
    ID               serial PRIMARY KEY,
    tag              character varying(128)
);
COMMENT ON TABLE tags IS 'Словарь меток/тэгов.';

CREATE TABLE IF NOT EXISTS publishers (
    ID               serial PRIMARY KEY,
    "name"           character varying(1024)
);
COMMENT ON TABLE publishers IS 'Название организации, которая выпустила диск';

CREATE TABLE IF NOT EXISTS categories
(
    ID               serial PRIMARY KEY,
    "name"           character varying(512)
);
COMMENT ON TABLE categories IS 'Категория лекции или коллекции.';

INSERT INTO categories (name) VALUES    ('семинары');
INSERT INTO categories (name) VALUES    ('ретриты');
INSERT INTO categories (name) VALUES    ('парикрама');
INSERT INTO categories (name) VALUES    ('публичные лекции');
INSERT INTO categories (name) VALUES    ('праздники');
INSERT INTO categories (name) VALUES    ('обращения');
INSERT INTO categories (name) VALUES    ('встречи с учениками');


CREATE TABLE IF NOT EXISTS scriptures
(
    ID               serial PRIMARY KEY,
    "name"           character varying(512)
);
COMMENT ON TABLE categories IS 'Священные писания, названия';
INSERT INTO scriptures (name) VALUES    ('Бхагавад-гита');
INSERT INTO scriptures (name) VALUES    ('Шримад Бхагаватам');
INSERT INTO scriptures (name) VALUES    ('Чайтанья-чаритамрита (Ади лила)');
INSERT INTO scriptures (name) VALUES    ('Чайтанья-чаритамрита (Мадхья лила)');
INSERT INTO scriptures (name) VALUES    ('Чайтанья-чаритамрита (Антья лила)');
INSERT INTO scriptures (name) VALUES    ('Нектар преданности');
INSERT INTO scriptures (name) VALUES    ('Нектар наставлений');
INSERT INTO scriptures (name) VALUES    ('Шри Ишопанишад');




-- МЕДИА ОБЪЕКТЫ (ФАЙЛЫ) В КОЛЛЕКЦИИ (ДИСКЕ)

-- type ('audio', 'book', 'article', 'picture', 'collection');

CREATE TABLE IF NOT EXISTS media (
    ID               serial PRIMARY KEY,
    type             character varying(128),
    title            character varying(2096),
    teaser           text,
    jira_ref         character varying(128),
    body             text,
    occurrence_date  date,
    issue_date       date,
    publisher_id     integer references publishers(ID),  -- производитель диска или еще чего нибудь
    category_id      integer references categories(ID),
    scripture_id     integer references scriptures(ID),
    canto            integer, -- песнь
    chapter          integer, -- глава
    verse            integer, -- стих
    img_url          text,   -- ссылка на картинку, для диска и лекции ссылка на ковер например
    file_url         text,   -- ссылка на файл лекции
    alias_url        text,   -- красивая ссылка
    location_id      integer references locations(ID),
    visible          boolean DEFAULT true,
    duration         interval,
    size             integer,
    language         char(3) DEFAULT 'RUS'
);
COMMENT ON TABLE media IS 'Коллекция, лекция, книга, статья или фотография';

CREATE TABLE IF NOT EXISTS media_tags (
    ID               serial PRIMARY KEY,
    media_id         integer references media(ID) on delete cascade,
    tag_id           integer references tags(ID) on delete cascade
);
COMMENT ON TABLE media_tags IS 'Связка лекции и её тэгов.';

CREATE TABLE IF NOT EXISTS media_authors
(
    ID                serial PRIMARY KEY,
    author_id         integer references authors(ID) on delete cascade,
    media_id          integer references media(ID) on delete cascade
);
COMMENT ON TABLE media_authors IS 'В одном файле (media) может быть несколько выступающих.';

-- data_type  ('picture', 'video', 'directory');
CREATE TABLE media_data
(
    ID                serial PRIMARY KEY,
    media_id          integer references media(ID) on delete cascade,
    data_type         character varying(128),
    value             text
);
COMMENT ON TABLE media_data IS 'дополнительные атрибуты объекта ';


CREATE TABLE IF NOT EXISTS news
(
    ID                serial PRIMARY KEY,
    title             character varying(255),
    teaser            text,
    body              text,
    "date"            date
);
COMMENT ON TABLE news IS 'Новости на сайте.';

CREATE TABLE IF NOT EXISTS carousel
(
    id                SERIAL PRIMARY KEY,
	  image_url         TEXT NOT NULL,
	  target_url        TEXT NOT NULL,
	  position          INTEGER NOT NULL,
	  visible           boolean default true
);
COMMENT ON TABLE carousel IS 'Список картинок для показа на главной странице';

/*
CREATE TABLE IF NOT EXISTS collection_media_sequence
(
    collection_id     integer references media(ID) on delete cascade,
    media_id          integer references media(ID) on delete cascade,
    sequence_number   integer,
    CONSTRAINT collection_media_sequence UNIQUE (collection_id, media_id)
);
COMMENT ON TABLE collection_media_sequence IS 'sequence_number - порядковый номер лекции (media) в диске (коллекции). Одна и таже лекция может входить в разные диски (коллекции)';
*/


CREATE TABLE IF NOT EXISTS xref_media
(
    ID               serial PRIMARY KEY,
    media_id         integer references media(ID) on delete cascade,
    linked_media_id  integer references media(ID) on delete cascade,
    sequence_number  integer
);
COMMENT ON TABLE xref_media IS 'Любой медиа объект может быть связан с любым списком других медиа объектов. Одна новость может быть связана с любым количеством лекций, видео, фотографий и т.д.';


CREATE TABLE IF NOT EXISTS playlists
(
    ID               serial PRIMARY KEY,
    media_id         integer NOT NULL references media(ID) on delete cascade
);
COMMENT ON TABLE playlists IS 'Списки проигрывания';

CREATE TABLE IF NOT EXISTS users
(
    id               serial PRIMARY KEY,
    email            varchar(254) NOT NULL,
    username         varchar(254),
    "password"       varchar(64) NOT NULL,
    logins           integer NOT NULL DEFAULT 0,
    last_login       integer,
    CONSTRAINT       users_email_key UNIQUE (email),
    CONSTRAINT       users_logins_check CHECK (logins >= 0)
);
COMMENT ON TABLE users IS 'Основные данные пользователей';

CREATE TABLE IF NOT EXISTS user_playlists
(
    ID               serial PRIMARY KEY,
    playlist_name    varchar(1024) NOT NULL,
    user_id          integer NOT NULL references users(ID) on delete cascade,
    playlist_id      integer NOT NULL references playlists(ID) on delete cascade
);
COMMENT ON TABLE user_playlists IS 'Списки проигрывания пользователей';

/* Based on auth-schema-postgresql.sql from ORM module */
CREATE TABLE IF NOT EXISTS roles
(
    id               serial PRIMARY KEY,
    "name"           varchar(32) NOT NULL,
    description      text NOT NULL,
    CONSTRAINT       roles_name_key UNIQUE (name)
);
COMMENT ON TABLE roles IS 'Поисковые слова на каждый объект (лекцию).';

CREATE TABLE IF NOT EXISTS roles_users
(
    id               serial PRIMARY KEY,
    user_id          integer references users(ID) on delete cascade,
    role_id          integer
);
COMMENT ON TABLE roles IS 'Роли пользователей';

CREATE TABLE IF NOT EXISTS user_data
(
    ID               serial PRIMARY KEY,
    user_id          integer NOT NULL,
    "name"           varchar(254),
    avatar           varchar(254),
    spiritual_name   varchar(254),
    city             varchar(254),
    activity         varchar(254),
    phone            varchar(64),
    birth_date       DATE,
    sex              boolean DEFAULT true,
    email_subscriber boolean DEFAULT false,
    geo_location     varchar(128),
    rank             integer DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS user_tokens
(
    ID               serial PRIMARY KEY,
    user_id          integer NOT NULL,
    user_agent       varchar(254) NOT NULL,
    token            character varying(254) NOT NULL,
    created          integer NOT NULL,
    expires          integer NOT NULL,
    CONSTRAINT       user_tokens_token_key UNIQUE (token)
);


CREATE INDEX user_id_idx ON roles_users (user_id);
CREATE INDEX role_id_idx ON roles_users (role_id);

ALTER TABLE roles_users
  ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  ADD CONSTRAINT role_id_fkey FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  ADD CONSTRAINT roles_users_key UNIQUE (user_id, role_id);

ALTER TABLE user_tokens
  ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE user_data
  ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

INSERT INTO roles (name, description) VALUES ('login', 'Login privileges, granted after account confirmation');
INSERT INTO roles (name, description) VALUES ('admin', 'Administrative user, has access to everything.');
INSERT INTO roles (name, description) VALUES ('representative', 'Распространители дисков');
INSERT INTO roles (name, description) VALUES ('team', 'Участники студии');


CREATE TABLE donations (
	id               serial PRIMARY KEY,
  title            varchar(254) NOT NULL,
	description      text,
	img_url          varchar(254),
	amount           money,
	necessary_amount money,
	end_date         date,
	latest_recharge  date,
	currency         varchar(3) NOT NULL DEFAULT 'RUR'
);

INSERT INTO donations (title, description, img_url, amount, necessary_amount, end_date, latest_recharge)
    VALUES
    (
            'Размещение сервера студии в датацентре',
            'Сервер где хранятся все видео и аудио материалы размещен в датацентре.',
            '/content/studio/engeneer.png',
            10000,
            30900,
            '20161225',
            '20160203'
    );

CREATE TABLE vacancy (
	id               serial PRIMARY KEY,
	title            varchar(254) NOT NULL,
	description      text,
	img_url          varchar(254),
	contact_id       integer,
	FOREIGN KEY (contact_id)
		REFERENCES users ("id")
		ON UPDATE NO ACTION ON DELETE SET DEFAULT
);

DO $$DECLARE r record;
BEGIN
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' and tableowner <> 'pgsql'
    LOOP
        EXECUTE 'alter table '|| r.tablename ||' owner to "goswami.ru";';
    END LOOP;
END$$;

-------------- migration






