-- name: install-drop-tables
DROP TABLE IF EXISTS
    timeline, chapter, player, persona, post,
    chapter_link, chapter_permission, timeline_permission,
    global_chapter_permission;

-- name: install-drop-types
DROP TYPE IF EXISTS
    ch_permission, tl_permission;

-- name: install-create-ch-permission
CREATE TYPE ch_permission AS ENUM (
        'administer'
        'view_chapter',
        'edit_own_posts',
        'edit_others_posts',
        'rearrange_posts',
        'create_posts',
        'delete_posts',
        'assign_persona',
        'change_chapter_permissions',
        'change_chapter_name');

-- name: install-create-tl-permission
CREATE TYPE tl_permission AS ENUM (
        'administer',
        'view_timeline',
        'link_within_timeline',
        'link_from_timeline',
        'link_to_timeline',
        'change_timeline_permissions',
        'change_timeline_name');

-- name: install-create-table-timeline
CREATE TABLE timeline (
        timeline_id    serial        NOT NULL PRIMARY KEY,
        timeline       varchar(80)   NOT NULL);

-- name: install-create-table-chapter
CREATE TABLE chapter (
        chapter_id     serial        NOT NULL PRIMARY KEY,
        chapter        varchar(80)   NOT NULL,
        timeline_id    integer       NOT NULL REFERENCES timeline(timeline_id)
        ON UPDATE CASCADE);

-- name: install-create-table-player
CREATE TABLE player (
        player_id      serial        NOT NULL PRIMARY KEY,
        player         varchar(80)   NOT NULL,
        email          varchar(80)   NOT NULL,
        passhash       bytea         NOT NULL);

-- name: install-create-table-persona
CREATE TABLE persona (
        persona_id     serial        NOT NULL PRIMARY KEY,
        persona        varchar(80)   NOT NULL,
        owner          integer       NOT NULL REFERENCES player(player_id)
        ON UPDATE CASCADE,
        borrower       integer       NOT NULL REFERENCES player(player_id)
        ON UPDATE CASCADE,
        description    text          NOT NULL);

-- name: install-create-table-post
CREATE TABLE post (
        post_id        serial        NOT NULL PRIMARY KEY,
        player_id      integer       NOT NULL REFERENCES player(player_id)
        ON UPDATE CASCADE,
        persona_id     integer       NOT NULL REFERENCES persona(persona_id)
        ON UPDATE CASCADE,
        post_time      timestamp     NOT NULL,
        contents       text          NOT NULL,
        chapter_id     integer       NOT NULL REFERENCES chapter(chapter_id)
        ON UPDATE CASCADE,
        chapter_order  integer       NOT NULL,
        CONSTRAINT     id_order      UNIQUE(chapter_id, chapter_order));

-- name: install-create-table-chapter-link
CREATE TABLE chapter_link (
        link_from      integer       NOT NULL REFERENCES chapter(chapter_id)
        ON UPDATE CASCADE,
        link_to        integer       NOT NULL REFERENCES chapter(chapter_id)
        ON UPDATE CASCADE,
        CONSTRAINT     chapter_link_primary_key
        PRIMARY KEY (link_from, link_to));

-- name: install-create-table-chapter-permission
CREATE TABLE chapter_permission (
        player_id      integer       NOT NULL REFERENCES player(player_id)
        ON UPDATE CASCADE,
        chapter_id     integer       NOT NULL REFERENCES chapter(chapter_id)
        ON UPDATE CASCADE,
        permission     ch_permission NOT NULL,
        CONSTRAINT     chapter_permission_primary_key
        PRIMARY KEY (player_id, chapter_id, permission));

-- name: install-create-table-timeline-permission
CREATE TABLE timeline_permission (
        player_id      integer       NOT NULL REFERENCES player(player_id)
        ON UPDATE CASCADE,
        timeline_id    integer       NOT NULL REFERENCES timeline(timeline_id)
        ON UPDATE CASCADE,
        permission     tl_permission NOT NULL,
        CONSTRAINT     timeline_permission_primary_key
        PRIMARY KEY (player_id, timeline_id, permission));

-- name: install-create-table-global-chapter-permission
CREATE TABLE global_chapter_permission (
        timeline_id    integer       NOT NULL REFERENCES timeline(timeline_id)
        ON UPDATE CASCADE,
        permission     ch_permission NOT NULL,
        CONSTRAINT global_chapter_permission_primary_key
        PRIMARY KEY (timeline_id, permission));