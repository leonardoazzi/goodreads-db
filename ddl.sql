-- Entidade: Series
-- Descrição: Uma série de livros contendo uma ou mais obras primárias explicitamente
-- ordenadas e, opcionalmente, outras obras sem uma posição específica dentro da série.
create table SERIES
(id integer not null primary key,
title varchar(100) not null);

-- Entidade: Work
-- Descrição: Uma obra literária que engloba todas as suas edições.
create table WORKS
(id integer not null primary key,
title varchar(100) not null,
first_publication_date date not null,
rating numeric(2) check (0.0 <= rating and rating <= 5.0));	-- NOTA MÉDIA DE 0 A 5

-- Entidade: Genre
-- Descrição: Um gênero ou categoria de livros. É definido pelo seu nome e usado para
-- agrupar obras com características similares.
create table GENRES
(slug varchar(50) not null primary key,
label varchar(50) not null,
description varchar(2000));

-- Entidade: Author
-- Descrição: Um autor com zero ou mais obras atribuídas a si. Usado para agrupar livros
-- escritos pela mesma pessoa e fornecer informações sobre estas através de um perfil. Pode
-- ser definido antes de suas obras.
create table AUTHORS
(id integer not null primary key,
name varchar(150) not null,
picture varchar(500),
birth_place varchar(50),
birth_date date,
death_date date,
website varchar(500),
biography varchar(2000));

-- Entidade: Edition
-- Descrição: Uma edição ou instância de uma obra. Usado na maior parte das listagens para
-- representar uma obra, pois a mesma pode ter diversas variações com diferenças
-- significativas.
-- ===========================================================================================
-- Publication
-- Relacionamento: Publication
-- Descrição: Atribui uma edição à obra a qual ela corresponde.
-- Entidades participantes:
-- ●​ Work: (1, 1) é instância de
-- ●​ Edition: (1, n) possui
-- ===========================================================================================
create table EDITIONS
(id integer not null primary key,
work_id integer not null references WORKS(id), -- Relacionamento Publication
title varchar(150) not null,
page_count smallint not null,
format varchar(25) not null,
publication_date date not null,
publisher varchar(50) not null,
language varchar(50) not null,
cover varchar(500),
summary varchar(2000),
isbn char(13),
asin char(10));

-- Entidade: User
-- Descrição: Um usuário criado quando um cadastro é feito na plataforma com email e
-- senha. Representa também um perfil. É necessário para fazer interações no site.
create table USERS
(id integer not null primary key,
email varchar(254) not null unique,
password varchar(35) not null,
first_name varchar(50) not null,
last_name varchar(50),
picture varchar(500));

-- Entidade: Group
-- Descrição: Um grupo criado e composto por usuários, que podem ser moderadores ou
-- membros. Moderadores podem atribuir um ou mais livros como a leitura do grupo durante
-- um período de tempo especificado.
create table GROUPS
(id integer not null primary key,
name varchar(100) not null,
description varchar(1000),
picture varchar(500));

-- Entidade: List
-- Descrição: Uma lista de livros pública criada por um usuário mas sem atribuição ao
-- mesmo. Qualquer usuário pode adicionar livros à lista, assim como votar em obras já
-- listadas.
create table LISTS
(id integer not null primary key,
title varchar(100) not null,
description varchar(1000));

-- Entidade: ListEntry
-- Descrição: Uma listagem de um livro em uma lista. Representa uma obra específica
-- dentro de uma lista, podendo conter informações adicionais como a posição na lista e
-- a data de adição.
-- ===========================================================================================
-- Entry
-- Relacionamento: Entry
-- Descrição: Atribui uma listagem de um livro à lista na qual ela foi feita.
-- Entidades participantes:
-- ●​ ListEntry: (0, n) possui
-- ●​ List: (1, 1) faz parte de
-- ============================================================================================
create table EDITION_LISTENTRY
(edition_id integer not null primary key references EDITIONS(id), -- Relacionamento Entry
 vote_count integer not null check (vote_count >= 0),
 list_id integer not null references LISTS(id));

-- Entidade: Shelf
-- Descrição: Uma estante ou coleção de livros públicas de um usuário. Não inclui as
-- prateleiras “to-read”, “currently-reading e “read” presentes na plataforma original, as
-- mesmas foram convertidas no relacionamento Tracking.
create table SHELVES
(slug varchar(50) not null primary key);

-- Entidade: Quote
-- Descrição: Uma citação. Frase ou texto atribuída a um autor por um usuário. Pode ser
-- “curtida” por outros usuários.
-- ===========================================================================================
-- Attribution
-- Relacionamento: Attribution
-- Descrição: Atribui a autoria de uma citação a um autor.
-- Entidades participantes:
-- ●​ Author: (1, 1) é atribuído a
-- ●​ Quote: (0, n) é dono de
-- ===========================================================================================
create table QUOTES
(id integer not null primary key,
 quote varchar(500) not null,
 author_id integer not null references AUTHORS(id));

-- MAPEAMENTO DE RELACIONAMENTOS N:M

-- Relacionamento: Positioning
-- Descrição: Atribui uma obra a uma série, com ou sem uma posição específica em relação
-- às outras obras da série.
-- Entidades participantes:
-- ●​ Series: (1, n) contém
-- ●​ Work: (0, n) faz parte de
create table POSITIONINGS
(series_id integer not null references SERIES(id),
 work_id integer not null references WORKS(id),
 position numeric(2) not null);

-- Categorization
-- Relacionamento: Categorization
-- Descrição: Atribui uma obra a uma categoria ou gênero de livros.
-- Entidades participantes:
-- ●​ Work: (0, n) categoriza
-- ●​ Genre: (0, n) é categorizado como
create table CATEGORIZATIONS
(work_id integer not null references WORKS(id),
 genre_slug varchar(50) not null references GENRES(slug));

-- Authorship
-- Relacionamento: Authorship
-- Descrição: Atribui uma obra aos autores que a escreveram.
-- Entidades participantes:
-- ●​ Work: (0, n) escreveu
-- ●​ Author: (1, n) foi escrito por
create table AUTHORSHIPS
(work_id integer not null references WORKS(id),
 author_id integer not null references AUTHORS(id));

-- Storage
-- Relacionamento: Storage
-- Descrição: Atribui uma edição de um livro a uma estante de um usuário.
-- Entidades participantes:
-- ●​ Edition: (0, n) contém
-- ●​ Shelf: (0, n) está contido em
create table STORAGES
(edition_id integer not null references EDITIONS(id),
 shelf_slug varchar(50) not null references SHELVES(slug));

-- Ownership
-- Relacionamento: Ownership
-- Descrição: Atribui uma estante ao usuário ao qual ela pertence.
-- Entidades participantes:
-- ●​ Shelf: (0, n) possui
-- ●​ User: (1, 1) pertence a
create table OWNERSHIPS
(shelf_slug varchar(50) not null references SHELVES(slug),
 user_id integer not null references USERS(id));

-- Tracking
-- Relacionamento: Tracking
-- Descrição: Guarda o status e progresso atual de um usuário em relação à leitura de um
-- livro. Pode conter mais de uma leitura e, também, uma avaliação.
-- Entidades participantes:
-- ●​ Edition: (0, n) rastreia
-- ●​ User: (0, n) é rastreado por
create table TRACKINGS
(edition_id integer not null references EDITIONS(id),
 user_id integer not null references USERS(id),
 progress smallint default 0,
 rating smallint check (0.0 <= rating and rating <= 5.0), -- NOTA DE 0 A 5
 review varchar(18800),
 reading_period daterange);

-- Like
-- Relacionamento: Like
-- Descrição: Ligação criada quando um usuário curte uma citação.
-- Entidades participantes:
-- ●​ Quote: (0, n) curtiu
-- ●​ User: (0, n) foi curtido por
create table LIKES
(quote_id integer not null references QUOTES(id),
 user_id integer not null references USERS(id));

-- Membership
-- Relacionamento: Membership
-- Descrição: Atribui um usuário a um grupo do qual ele faz parte.
-- Entidades participantes:
-- ●​ User: (1, n) tem como membro
-- ●​ Group: (0, n) é membro de
create table MEMBERSHIPS
(user_id integer not null references USERS(id),
 group_id integer not null references GROUPS(id));

-- Moderation
-- Relacionamento: Moderation
-- Descrição: Atribui a posição de moderador de um grupo a um usuário. Pode ou não ser um
-- membro do grupo.
-- Entidades participantes:
-- ●​ User: (1, n) é moderado por
-- ●​ Group: (0, n) modera
create table MODERATIONS
(user_id integer not null references USERS(id),
 group_id integer not null references GROUPS(id));

-- CurrentlyReading
-- Relacionamento: CurrentlyReading
-- Descrição: Atribui um livro (edição) a um grupo, representando as leituras atuais deste
-- grupo. Pode incluir uma data de início e de fim.
-- Entidades participantes:
-- ● Edition: (0, n) está lendo
-- ● Group: (0, n) está sendo lido por
create table CURRENTLY_READINGS
(edition_id integer not null references EDITIONS(id),
 group_id integer not null references GROUPS(id),
 start_date date,
 finish_date date);

-- Vote
-- Relacionamento: Vote
-- Descrição: Ligação criada quando um usuário vota em um livro em uma lista.
-- Entidades participantes:
-- ● ListEntry: (0, n) votou em
-- ● User: (0, n) foi votado por
create table VOTES
(list_entry_id integer not null references LIST_ENTRIES(edition_id),
 user_id integer not null references USERS(id));