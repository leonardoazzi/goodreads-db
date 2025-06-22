-- Entidade: Series
-- Descrição: Uma série de livros contendo uma ou mais obras primárias explicitamente
-- ordenadas e, opcionalmente, outras obras sem uma posição específica dentro da série.
CREATE TABLE series (
	id INTEGER NOT NULL PRIMARY KEY,
	title VARCHAR(100) NOT NULL
);

-- Entidade: Work
-- Descrição: Uma obra literária que engloba todas as suas edições.
CREATE TABLE works (
	id INTEGER NOT NULL PRIMARY KEY,
	title VARCHAR(100) NOT NULL,
	first_publication_date DATE NOT NULL,
	rating NUMERIC(2) CHECK (
		0.0 <= rating
		AND rating <= 5.0
	)
);

-- NOTA MÉDIA DE 0 A 5
-- Entidade: Genre
-- Descrição: Um gênero ou categoria de livros. É definido pelo seu nome e usado para
-- agrupar obras com características similares.
CREATE TABLE genres (
	slug VARCHAR(50) NOT NULL PRIMARY KEY,
	label VARCHAR(50) NOT NULL,
	description VARCHAR(2000)
);

-- Entidade: Author
-- Descrição: Um autor com zero ou mais obras atribuídas a si. Usado para agrupar livros
-- escritos pela mesma pessoa e fornecer informações sobre estas através de um perfil. Pode
-- ser definido antes de suas obras.
CREATE TABLE authors (
	id INTEGER NOT NULL PRIMARY KEY,
	name VARCHAR(150) NOT NULL,
	picture VARCHAR(500),
	birth_place VARCHAR(50),
	birth_date DATE,
	death_date DATE,
	website VARCHAR(500),
	biography VARCHAR(2000)
);

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
CREATE TABLE editions (
	id INTEGER NOT NULL PRIMARY KEY,
	work_id INTEGER NOT NULL REFERENCES works(id),
	-- Relacionamento Publication
	title VARCHAR(150) NOT NULL,
	page_count SMALLINT NOT NULL,
	format VARCHAR(25) NOT NULL,
	publication_date DATE NOT NULL,
	publisher VARCHAR(50) NOT NULL,
	language VARCHAR(50) NOT NULL,
	cover VARCHAR(500),
	summary VARCHAR(2000),
	isbn CHAR(13),
	asin CHAR(10)
);

-- Entidade: User
-- Descrição: Um usuário criado quando um cadastro é feito na plataforma com email e
-- senha. Representa também um perfil. É necessário para fazer interações no site.
CREATE TABLE users (
	id INTEGER NOT NULL PRIMARY KEY,
	email VARCHAR(254) NOT NULL UNIQUE,
	password VARCHAR(35) NOT NULL,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50),
	picture VARCHAR(500)
);

-- Entidade: Group
-- Descrição: Um grupo criado e composto por usuários, que podem ser moderadores ou
-- membros. Moderadores podem atribuir um ou mais livros como a leitura do grupo durante
-- um período de tempo especificado.
CREATE TABLE groups (
	id INTEGER NOT NULL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	description VARCHAR(1000),
	picture VARCHAR(500)
);

-- Entidade: List
-- Descrição: Uma lista de livros pública criada por um usuário mas sem atribuição ao
-- mesmo. Qualquer usuário pode adicionar livros à lista, assim como votar em obras já
-- listadas.
CREATE TABLE lists (
	id INTEGER NOT NULL PRIMARY KEY,
	title VARCHAR(100) NOT NULL,
	description VARCHAR(1000)
);

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
CREATE TABLE edition_listentry (
	edition_id INTEGER NOT NULL PRIMARY KEY REFERENCES editions(id),
	-- Relacionamento Entry
	vote_count INTEGER NOT NULL CHECK (vote_count >= 0),
	list_id INTEGER NOT NULL REFERENCES lists(id)
);

-- Entidade: Shelf
-- Descrição: Uma estante ou coleção de livros públicas de um usuário. Não inclui as
-- prateleiras “to-read”, “currently-reading e “read” presentes na plataforma original, as
-- mesmas foram convertidas no relacionamento Tracking.
CREATE TABLE shelves (slug VARCHAR(50) NOT NULL PRIMARY KEY);

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
CREATE TABLE quotes (
	id INTEGER NOT NULL PRIMARY KEY,
	quote VARCHAR(500) NOT NULL,
	author_id INTEGER NOT NULL REFERENCES authors(id)
);

-- MAPEAMENTO DE RELACIONAMENTOS N:M
-- Relacionamento: Positioning
-- Descrição: Atribui uma obra a uma série, com ou sem uma posição específica em relação
-- às outras obras da série.
-- Entidades participantes:
-- ●​ series: (1, n) contém
-- ●​ Work: (0, n) faz parte de
CREATE TABLE positionings (
	series_id INTEGER NOT NULL REFERENCES series(id),
	work_id INTEGER NOT NULL REFERENCES works(id),
	position NUMERIC(2) NOT NULL
);

-- Categorization
-- Relacionamento: Categorization
-- Descrição: Atribui uma obra a uma categoria ou gênero de livros.
-- Entidades participantes:
-- ●​ Work: (0, n) categoriza
-- ●​ Genre: (0, n) é categorizado como
CREATE TABLE categorizations (
	work_id INTEGER NOT NULL REFERENCES works(id),
	genre_slug VARCHAR(50) NOT NULL REFERENCES genres(slug)
);

-- Authorship
-- Relacionamento: Authorship
-- Descrição: Atribui uma obra aos autores que a escreveram.
-- Entidades participantes:
-- ●​ Work: (0, n) escreveu
-- ●​ Author: (1, n) foi escrito por
CREATE TABLE authorships (
	work_id INTEGER NOT NULL REFERENCES works(id),
	author_id INTEGER NOT NULL REFERENCES authors(id)
);

-- Storage
-- Relacionamento: Storage
-- Descrição: Atribui uma edição de um livro a uma estante de um usuário.
-- Entidades participantes:
-- ●​ Edition: (0, n) contém
-- ●​ Shelf: (0, n) está contido em
CREATE TABLE storages (
	edition_id INTEGER NOT NULL REFERENCES editions(id),
	shelf_slug VARCHAR(50) NOT NULL REFERENCES shelves(slug)
);

-- Ownership
-- Relacionamento: Ownership
-- Descrição: Atribui uma estante ao usuário ao qual ela pertence.
-- Entidades participantes:
-- ●​ Shelf: (0, n) possui
-- ●​ User: (1, 1) pertence a
CREATE TABLE ownerships (
	shelf_slug VARCHAR(50) NOT NULL REFERENCES shelves(slug),
	user_id INTEGER NOT NULL REFERENCES users(id)
);

-- Tracking
-- Relacionamento: Tracking
-- Descrição: Guarda o status e progresso atual de um usuário em relação à leitura de um
-- livro. Pode conter mais de uma leitura e, também, uma avaliação.
-- Entidades participantes:
-- ●​ Edition: (0, n) rastreia
-- ●​ User: (0, n) é rastreado por
CREATE TABLE trackings (
	edition_id INTEGER NOT NULL REFERENCES editions(id),
	user_id INTEGER NOT NULL REFERENCES users(id),
	status ENUM('to-read', 'currently-reading', 'read') NOT NULL,
	progress SMALLINT DEFAULT 0,
	rating SMALLINT CHECK (
		0.0 <= rating
		AND rating <= 5.0
	),
	-- NOTA DE 0 A 5
	review VARCHAR(18800),
	reading_period DATERANGE
);

-- Like
-- Relacionamento: Like
-- Descrição: Ligação criada quando um usuário curte uma citação.
-- Entidades participantes:
-- ●​ Quote: (0, n) curtiu
-- ●​ User: (0, n) foi curtido por
CREATE TABLE likes (
	quote_id INTEGER NOT NULL REFERENCES quotes(id),
	user_id INTEGER NOT NULL REFERENCES users(id)
);

-- Membership
-- Relacionamento: Membership
-- Descrição: Atribui um usuário a um grupo do qual ele faz parte.
-- Entidades participantes:
-- ●​ User: (1, n) tem como membro
-- ●​ Group: (0, n) é membro de
CREATE TABLE memberships (
	user_id INTEGER NOT NULL REFERENCES users(id),
	group_id INTEGER NOT NULL REFERENCES groups(id)
);

-- Moderation
-- Relacionamento: Moderation
-- Descrição: Atribui a posição de moderador de um grupo a um usuário. Pode ou não ser um
-- membro do grupo.
-- Entidades participantes:
-- ●​ User: (1, n) é moderado por
-- ●​ Group: (0, n) modera
CREATE TABLE moderations (
	user_id INTEGER NOT NULL REFERENCES users(id),
	group_id INTEGER NOT NULL REFERENCES groups(id)
);

-- CurrentlyReading
-- Relacionamento: CurrentlyReading
-- Descrição: Atribui um livro (edição) a um grupo, representando as leituras atuais deste
-- grupo. Pode incluir uma data de início e de fim.
-- Entidades participantes:
-- ● Edition: (0, n) está lendo
-- ● Group: (0, n) está sendo lido por
CREATE TABLE currently_readings (
	edition_id INTEGER NOT NULL REFERENCES editions(id),
	group_id INTEGER NOT NULL REFERENCES groups(id),
	start_date DATE,
	finish_date DATE
);

-- Vote
-- Relacionamento: Vote
-- Descrição: Ligação criada quando um usuário vota em um livro em uma lista.
-- Entidades participantes:
-- ● ListEntry: (0, n) votou em
-- ● User: (0, n) foi votado por
CREATE TABLE votes (
	list_entry_id INTEGER NOT NULL REFERENCES LIST_ENTRIES(edition_id),
	user_id INTEGER NOT NULL REFERENCES users(id)
);
