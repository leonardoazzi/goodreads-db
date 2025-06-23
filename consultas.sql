-- ===========================================================================================
-- 2.a) VISÃO
-- ===========================================================================================

-- Visão: book_details - Combina informações de obras, edições, autores e gêneros
CREATE VIEW book_details AS
SELECT w.id as work_id,
	w.title as work_title,
	w.first_publication_date,
	w.mean_rating as work_rating,
	e.id as edition_id,
	e.title as edition_title,
	e.page_count,
	e.format,
	e.publication_date,
	e.publisher,
	e.language,
	e.isbn,
	e.cover_image_url,
	e.summary,
	a.id as author_id,
	a.name as author_name,
	a.birth_date as author_birth_date,
	g.id as genre_id,
	g.label as genre_label,
	g.slug as genre_slug
FROM works w
	JOIN editions e ON w.id = e.work_id
	JOIN authorships au ON w.id = au.work_id
	JOIN authors a ON au.author_id = a.id
	LEFT JOIN categorizations c ON w.id = c.work_id
	LEFT JOIN genres g ON c.genre_id = g.id;

-- ===========================================================================================
-- 2.b) CONSULTAS
-- ===========================================================================================

-- Consulta 1: Listar todos os livros com suas informações completas usando a visão
-- Envolve: book_details (visão)
SELECT work_title,
	edition_title,
	author_name,
	genre_label,
	work_rating,
	page_count,
	publisher
FROM book_details
WHERE work_rating >= 4.5
ORDER BY work_rating DESC,
	work_title;

-- Consulta 2: Encontrar usuários que leram livros de todos os gêneros disponíveis
-- Envolve: users, trackings, editions, works, categorizations, genres
-- Relacionamentos: Tracking, Publication, Categorization
SELECT DISTINCT u.first_name,
	u.last_name,
	u.email
FROM users u
WHERE NOT EXISTS (
		SELECT g.id
		FROM genres g
		WHERE NOT EXISTS (
				SELECT 1
				FROM trackings t
					JOIN editions e ON t.edition_id = e.id
					JOIN works w ON e.work_id = w.id
					JOIN categorizations c ON w.id = c.work_id
				WHERE t.user_id = u.id
					AND t.status = 'read'
					AND c.genre_id = g.id
			)
	);

-- Consulta 3: Estatísticas de leitura por gênero com GROUP BY e HAVING
-- Envolve: trackings, editions, works, categorizations, genres
-- Relacionamentos: Tracking, Publication, Categorization
SELECT g.label as genre,
	COUNT(DISTINCT t.user_id) as total_readers,
	AVG(t.rating) as avg_rating,
	COUNT(*) as total_readings
FROM trackings t
	JOIN editions e ON t.edition_id = e.id
	JOIN works w ON e.work_id = w.id
	JOIN categorizations c ON w.id = c.work_id
	JOIN genres g ON c.genre_id = g.id
WHERE t.status = 'read'
GROUP BY g.id,
	g.label
HAVING COUNT(DISTINCT t.user_id) >= 1
ORDER BY total_readers DESC;

-- Consulta 4: Autores mais populares baseado em curtidas de citações
-- Envolve: likes, quotes, authors
-- Relacionamentos: Like, Attribution
SELECT a.name as author_name,
	COUNT(l.quote_id) as total_likes,
	COUNT(DISTINCT l.user_id) as unique_likers
FROM authors a
	JOIN quotes q ON a.id = q.author_id
	LEFT JOIN likes l ON q.id = l.quote_id
GROUP BY a.id,
	a.name
ORDER BY total_likes DESC;

-- Consulta 5: Listar séries com informações de posicionamento usando a visão (usa a visão)
-- Envolve: series, positionings, book_details (visão)
-- Relacionamentos: Positioning
SELECT s.title as series_title,
	bd.work_title,
	bd.author_name,
	p.position,
	bd.work_rating
FROM series s
	JOIN positionings p ON s.id = p.series_id
	JOIN book_details bd ON p.work_id = bd.work_id
ORDER BY s.title,
	p.position;

-- Consulta 6: Usuários que completaram seus desafios de leitura anual (REPLACED)
-- Envolve: users, trackings, editions, works
-- Relacionamentos: Tracking, Publication
SELECT u.first_name,
	u.last_name,
	EXTRACT(
		YEAR
		FROM t.finish_date
	) as reading_year,
	COUNT(*) as books_read,
	AVG(t.rating) as avg_rating,
	SUM(e.page_count) as total_pages
FROM users u
	JOIN trackings t ON u.id = t.user_id
	JOIN editions e ON t.edition_id = e.id
WHERE t.status = 'read'
	AND t.finish_date IS NOT NULL
GROUP BY u.id,
	u.first_name,
	u.last_name,
	EXTRACT(
		YEAR
		FROM t.finish_date
	)
HAVING COUNT(*) >= 12
ORDER BY reading_year DESC,
	books_read DESC;

-- Consulta 7: Recomendações de livros baseadas em gêneros favoritos dos usuários
-- Envolve: users, trackings, editions, works, categorizations, genres
-- Relacionamentos: Tracking, Publication, Categorization
SELECT u.first_name,
	u.last_name,
	g.label as favorite_genre,
	w.title as recommended_book,
	w.mean_rating as book_rating,
	a.name as author_name
FROM users u
	JOIN (
		SELECT t.user_id,
			c.genre_id,
			COUNT(*) as read_count
		FROM trackings t
			JOIN editions e ON t.edition_id = e.id
			JOIN works w ON e.work_id = w.id
			JOIN categorizations c ON w.id = c.work_id
		WHERE t.status = 'read'
			AND t.rating >= 4
		GROUP BY t.user_id,
			c.genre_id
		HAVING COUNT(*) >= 3
	) user_genres ON u.id = user_genres.user_id
	JOIN genres g ON user_genres.genre_id = g.id
	JOIN categorizations c ON g.id = c.genre_id
	JOIN works w ON c.work_id = w.id
	JOIN editions e ON w.id = e.work_id
	JOIN authorships au ON w.id = au.work_id
	JOIN authors a ON au.author_id = a.id
WHERE w.mean_rating >= 4.0
	AND NOT EXISTS (
		SELECT 1
		FROM trackings t2
		WHERE t2.user_id = u.id
			AND t2.edition_id = e.id
	)
ORDER BY u.first_name,
	g.label,
	w.mean_rating DESC;

-- Consulta 8: Atividade de leitura dos amigos de um usuário
-- Envolve: users, friendships, trackings, editions, works
-- Relacionamentos: Friendship, Tracking, Publication
SELECT u.first_name,
	u.last_name,
	friend.first_name as friend_name,
	friend.last_name as friend_last_name,
	w.title as book_title,
	t.status as reading_status,
	t.rating,
	t.finish_date
FROM users u
	JOIN friendships f ON u.id = f.user_id
	JOIN users friend ON f.friend_id = friend.id
	JOIN trackings t ON friend.id = t.user_id
	JOIN editions e ON t.edition_id = e.id
	JOIN works w ON e.work_id = w.id
WHERE t.finish_date >= CURRENT_DATE - INTERVAL '30 days'
	OR t.status = 'currently_reading'
ORDER BY u.first_name,
	friend.first_name,
	t.finish_date DESC;

-- Consulta 9: Análise de progresso de leitura por formato de livro
-- Envolve: trackings, editions, users
-- Relacionamentos: Tracking, Publication
SELECT e.format,
	COUNT(DISTINCT t.user_id) as unique_readers,
	COUNT(*) as total_trackings,
	AVG(t.progress) as avg_progress,
	COUNT(t.id) as total_entries
FROM trackings t
	JOIN editions e ON t.edition_id = e.id
	JOIN users u ON t.user_id = u.id
GROUP BY e.format
ORDER BY total_trackings DESC;

-- Consulta 10: Estatísticas de leitura detalhadas por usuário
-- Envolve: users, trackings, editions, works, categorizations, genres
-- Relacionamentos: Tracking, Publication, Categorization
SELECT u.first_name,
	u.last_name,
	COUNT(DISTINCT t.id) as total_books_read,
	AVG(t.rating) as avg_rating,
	SUM(e.page_count) as total_pages_read,
	COUNT(DISTINCT g.id) as genres_explored,
	MAX(t.finish_date) as last_book_finished,
	COUNT(
		CASE
			WHEN t.status = 'currently_reading' THEN 1
		END
	) as currently_reading
FROM users u
	LEFT JOIN trackings t ON u.id = t.user_id
	LEFT JOIN editions e ON t.edition_id = e.id
	LEFT JOIN works w ON e.work_id = w.id
	LEFT JOIN categorizations c ON w.id = c.work_id
	LEFT JOIN genres g ON c.genre_id = g.id
WHERE t.status IN ('read', 'currently_reading')
GROUP BY u.id,
	u.first_name,
	u.last_name
HAVING COUNT(DISTINCT t.id) >= 1
ORDER BY total_books_read DESC;
