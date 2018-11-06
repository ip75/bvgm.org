-- to update schema delete old tables

DROP TABLE IF EXISTS venues, authors, tags, tag_sets, tag_sets_tags, collections, collection_media_seq, publishers CASCADE;
DROP TABLE IF EXISTS media, xref_media, media_authors, search_words, news_media_objects, news, settings CASCADE;
DROP TYPE  IF EXISTS collection_type, media_type CASCADE;

-- СИСТЕМНЫЕ ТАБЛИЦЫ

CREATE TABLE IF NOT EXISTS settings (
    key              character varying(255),
    value            character varying(255)
);
COMMENT ON TABLE settings IS 'Настройки общие';

INSERT INTO settings (key, value) VALUES ('version', '0.1.1');

/*

-- ДИСКИ / КОЛЛЕКЦИИ

CREATE TYPE collection_type AS ENUM ('AUDIO', 'VIDEO');


-- пока убираем, до появления новых полей в этом объекте. Пока все поля ложатся в таблицу media,
-- хотя по смыслу это и контейнер, как и новость. Причина: новость должна быть связана с диском / коллекцией для публикации новостей,
-- также диск / коллекция включены в поиск по сайту, а в одной таблице легче искать чем в нескольких.

CREATE TABLE IF NOT EXISTS collections (
    ID              serial NOT NULL UNIQUE,
    name            character varying(255),
    title           character varying(255),
    teaser          text,
    description     text,
    type            collection_type,
    issue_date      date,
    publisher       character varying(255),
    cover_img_uri   text
);
COMMENT ON TABLE collections IS 'Описание выпускаемых дисков (коллекций). Лекции или видео могут входить в определенный диск.';

CREATE OR REPLACE FUNCTION fn_collections_add()
  RETURNS trigger AS
$BODY$
BEGIN
    INSERT INTO media(type, name, title, teaser, annotation, issue_date, publisher, img_uri)
    VALUES( 'collection', NEW.name, NEW.title, NEW.teaser, NEW.description, NEW.issue_date, NEW.publisher, NEW.cover_img_uri);

    RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_collections_rm()
  RETURNS trigger AS
$BODY$
BEGIN
    delete media when title = OLD.title and issue_date = OLD.issue_date;   -- полный отстой, так нельзя делать, нужно ключевое поле для связки
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_collections_update()
  RETURNS trigger AS
$BODY$
BEGIN
    update media set name = NEW.name, title = NEW.title, teaser = NEW.teaser, annotation = NEW.description, issue_date = NEW.issue_date, publisher = NEW.publisher, img_uri = NEW.publisher
    where NEW.issue_date = OLD.issue_date  -- полный отстой, так нельзя делать, нужно ключевое поле для связки
END;
$BODY$ LANGUAGE plpgsql;


-- автоматическое добавление / удаление в media записи о диске / коллекции с помощью триггера.
CREATE TRIGGER tr_collections_add
AFTER INSERT ON collections
FOR EACH ROW
EXECUTE PROCEDURE fn_collections_add();

CREATE TRIGGER tr_collections_delete
AFTER INSERT ON collections
FOR EACH ROW
EXECUTE PROCEDURE fn_collections_rm();

CREATE TRIGGER tr_collections_update
AFTER INSERT ON collections
FOR EACH ROW
EXECUTE PROCEDURE fn_collections_update();

--- !!! ничего не проверял. Не знаю как работает, просто идея как решить данную проблему.
*/

-- СПРАВОЧНИК ГОРОДОВ / МЕСТ ГДЕ ГУРУ МАХАРАДЖ И ЕГО УЧЕНИКИ ДАЮТ ЛЕКЦИИ
CREATE TABLE IF NOT EXISTS venues (
    ID               serial NOT NULL UNIQUE,
    name             character varying(255)
);
COMMENT ON TABLE venues IS 'Справочник городов где читались лекции, семинары и т.д.';


-- СПРАВОЧНИК АВТОРОВ
CREATE TABLE IF NOT EXISTS authors (
    ID               serial NOT NULL UNIQUE,
    name             character varying(255)
);

CREATE TABLE IF NOT EXISTS tags (
    ID               serial NOT NULL UNIQUE,
    tag              character varying(128)
);
COMMENT ON TABLE tags IS 'Словарь меток/тэгов.';

/*
-- бесполезная таблица, только все усложняет
CREATE TABLE IF NOT EXISTS tag_sets (
    ID               serial NOT NULL UNIQUE,
    tag_set_name     text
);
COMMENT ON TABLE tag_sets IS 'Коллекции меток/тэгов.';

CREATE TABLE IF NOT EXISTS tag_sets_tags (
    ID               serial NOT NULL UNIQUE,
    tag_id           integer references tags(ID) on delete cascade,
    tag_set_id       integer references tag_sets(ID) on delete cascade
);
COMMENT ON TABLE tag_sets_tags IS 'Связка словаря и коллекции меток/тэгов.';
*/


/*
-- перенос данных из tag_sets_tags
INSERT INTO media_tag (media_id, tag_id)
SELECT m.id, t.id
              FROM media m
              join tag_sets ts on m.tag_set_id = ts.id
              join tag_sets_tags tst on ts.id = tst.tag_set_id
              join tags t on t.id = tst.tag_id
*/


CREATE TABLE IF NOT EXISTS media_tag (
    ID               serial NOT NULL UNIQUE,
    media_id         integer references media(ID) on delete cascade,
    tag_id           integer references tags(ID) on delete cascade
);
COMMENT ON TABLE media_tag IS 'Связка лекции и её тэгов.';



CREATE TABLE IF NOT EXISTS publishers (
    ID               serial NOT NULL UNIQUE,
    name             character varying(1024)
);
COMMENT ON TABLE publishers IS 'Название организации, которая выпустила диск';

-- МЕДИА ОБЪЕКТЫ (ФАЙЛЫ) В КОЛЛЕКЦИИ (ДИСКЕ)

CREATE TYPE media_type AS ENUM ('audio', 'book', 'article', 'picture', 'collection');

CREATE TABLE IF NOT EXISTS media (
    ID               serial PRIMARY KEY,
    type             media_type,
    title            character varying(2096),
    teaser           text,
    jira_ref         character varying(128),
    body             text,
    occurrence_date  date,
    issue_date       date,
    publisher_id     integer references publishers(ID),  -- производитель диска или еще чего нибудь
    img_uri          text,   -- ссылка на картинку, для диска и лекции ссылка на ковер например
    file_uri         text,   -- ссылка на файл лекции
    alias_uri        text,   -- красивая ссылка
    venue_id         integer references venues(ID),
    podcast          boolean DEFAULT false,
    visible          boolean DEFAULT true,
    duration         interval,
    size             integer,
--    tag_set_id       integer references tag_sets(ID),
    language         char(3) DEFAULT 'RUS'
);
COMMENT ON TABLE media IS 'Коллекция (диск), лекция, книга, статья или фотографи. В общем любой медиа объект.';

CREATE TABLE IF NOT EXISTS media_authors (
    ID               serial NOT NULL,
    author_id        integer references authors(ID) on delete cascade,
    media_id         integer references media(ID) on delete cascade
);
COMMENT ON TABLE media_authors IS 'В одном файле (media) может быть несколько выступающих.';

CREATE TYPE media_data_type AS ENUM ('picture', 'video', 'directory');

CREATE TABLE media_data (
	ID               serial PRIMARY KEY,
    media_id         integer references media(ID) on delete cascade,
    data_type        media_data_type,
    value            text
);
COMMENT ON TABLE media_data IS 'дополнительные атрибуты объекта ';


CREATE TABLE IF NOT EXISTS news (
    ID               serial PRIMARY KEY,
    title            character varying(255),
    teaser           text,
    body             text,
    "date"           date,
    tag_set_id       integer references tag_sets(ID)
);
COMMENT ON TABLE tag_sets IS 'Новости на сайте.';


CREATE TABLE IF NOT EXISTS news_media_objects (
    ID               serial NOT NULL UNIQUE,
    news_id          integer references news(ID) on delete cascade,
    media_id         integer references media(ID) on delete cascade,
    major            boolean DEFAULT false
);
COMMENT ON TABLE news_media_objects IS 'медиа объекты, привязанные к новости';

CREATE TABLE IF NOT EXISTS collection_media_seq (
    collection_id    integer references media(ID) on delete cascade,
    media_id         integer references media(ID) on delete cascade,
    sequence_number  integer,
    CONSTRAINT collectio_media_key UNIQUE (collection_id, media_id)
);

COMMENT ON TABLE collection_media_seq IS 'sequence_number - порядковый номер лекции (media) в диске (коллекции). Одна и таже лекция может входить в разные диски (коллекции)';


CREATE TABLE IF NOT EXISTS xref_media (
    ID               serial NOT NULL,
    media_id         integer references media(ID) on delete cascade,
    linked_media_id  integer references media(ID) on delete cascade
);
COMMENT ON TABLE xref_media IS 'Любой медиа объект может быть связан с любым списком других медиа объектов. Одна новость может быть связана с любым количеством лекций, видео, фотографий и т.д.';


CREATE TABLE IF NOT EXISTS search_words (
    ID               serial NOT NULL,
    media_id         integer references media(ID) on delete cascade,
    word             character varying(128),
    weight           integer
);
COMMENT ON TABLE search_words IS 'Поисковые слова на каждый объект (лекцию).';

/* Based on auth-schema-postgresql.sql from ORM module */
CREATE TABLE roles (
    id               serial,
    "name"           varchar(32) NOT NULL,
    description      text NOT NULL,
    CONSTRAINT       roles_id_pkey PRIMARY KEY (id),
    CONSTRAINT       roles_name_key UNIQUE (name)
);
COMMENT ON TABLE roles IS 'Поисковые слова на каждый объект (лекцию).';

CREATE TABLE roles_users
(
    id               serial PRIMARY KEY,
    user_id          integer,
    role_id          integer
);
COMMENT ON TABLE roles IS 'Роли пользователей';

CREATE TABLE users
(
    id               serial,
    email            varchar(254) NOT NULL,
    username         varchar(254),
    "password"       varchar(64) NOT NULL,
    logins           integer NOT NULL DEFAULT 0,
    last_login       integer,
    CONSTRAINT       users_id_pkey PRIMARY KEY (id),
    CONSTRAINT       users_email_key UNIQUE (email),
    CONSTRAINT       users_logins_check CHECK (logins >= 0)
);
COMMENT ON TABLE users IS 'Основные данные пользователей';

CREATE TABLE user_data
(
    id               serial,
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
    rank             integer DEFAULT 0 NOT NULL,
    CONSTRAINT       user_data_id_pkey PRIMARY KEY (id)
);

CREATE TABLE user_tokens
(
    id               serial,
    user_id          integer NOT NULL,
    user_agent       varchar(254) NOT NULL,
    token            character varying(254) NOT NULL,
    created          integer NOT NULL,
    expires          integer NOT NULL,
    CONSTRAINT       user_tokens_id_pkey PRIMARY KEY (id),
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

CREATE TABLE pages (
	"id" serial PRIMARY KEY,
	"alias" varchar,
	"title" varchar,
	"is_in_main_menu" boolean DEFAULT false,
	parent_id integer,
	body text,
	teaser text,
	subtitle text,
	image_uri varchar,
	FOREIGN KEY (parent_id)
		REFERENCES pages ("id")
		ON UPDATE NO ACTION ON DELETE NO ACTION
);


CREATE TABLE donations (
	id               serial PRIMARY KEY,
    title            varchar(254) NOT NULL,
	description      text,
	img_uri          varchar(254),
	amount           money,
	necessary_amount money,
	end_date         date,
	latest_recharge  date,
	currency         varchar(3) NOT NULL DEFAULT 'RUR'
);

INSERT INTO donations (title, description, img_uri, amount, necessary_amount, end_date, latest_recharge)
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

CREATE TABLE vacancies (
	id               serial PRIMARY KEY,
	title            varchar(254) NOT NULL,
	description      text,
	img_uri          varchar(254),
	contact_id          integer,
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




-- create indices

CREATE UNIQUE INDEX authors_idx_id                            ON   authors(id);
CREATE UNIQUE INDEX media_idx_id                              ON   media(id);
CREATE INDEX media_idx_issue_date                             ON   media(issue_date);
CREATE INDEX media_idx_type                                   ON   media(type);
CREATE UNIQUE INDEX news_idx_id                               ON   news(id);
CREATE UNIQUE INDEX news_media_objects_idx_id                 ON   news_media_objects(id);
CREATE UNIQUE INDEX pages_idx_id                              ON   pages(id);
CREATE UNIQUE INDEX tag_sets_idx_id                           ON   tag_sets(id);
CREATE UNIQUE INDEX tag_sets_tags_idx_id                      ON   tag_sets_tags(id);
CREATE UNIQUE INDEX tags_idx_id                               ON   tags(id);
CREATE UNIQUE INDEX venues_idx_id                             ON   venues(id);
CREATE UNIQUE INDEX user_tokens_idx_id                        ON   user_tokens(id);
CREATE UNIQUE INDEX search_words_idx_id                       ON   search_words(id);
CREATE INDEX tag_sets_tags_idx_tag_set_id                     ON   tag_sets_tags(tag_set_id);
CREATE INDEX tag_sets_tags_idx_tag_set_id_tag_id              ON   tag_sets_tags(tag_set_id, tag_id);
CREATE INDEX xref_media_idx_id                                ON   xref_media(id);
CREATE INDEX xref_media_idx_media_id_linked_media_id          ON   xref_media(media_id, linked_media_id);

CREATE UNIQUE INDEX media_jira_ref_idx ON media (jira_ref);


