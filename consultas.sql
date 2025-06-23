-- ============================================================================
-- 2.a) VISÃO
-- ============================================================================

-- Visão: book_details - Contém todas as informações de um livro, combinando detalhes da obra, edições, autores e gêneros.
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

-- ============================================================================
-- 2.b) CONSULTAS
-- ============================================================================

-- Consulta 1: Todos os livros cadastrados, com os detalhes necessários para exibição
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

-- Consulta 2: Usuários que leram livros de todos os gêneros disponíveis
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

-- Consulta 3: Estatísticas de leitura por gênero
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
SELECT a.name as author_name,
	COUNT(l.quote_id) as total_likes,
	COUNT(DISTINCT l.user_id) as unique_likers
FROM authors a
	JOIN quotes q ON a.id = q.author_id
	LEFT JOIN likes l ON q.id = l.quote_id
GROUP BY a.id,
	a.name
ORDER BY total_likes DESC;

-- Consulta 5: Séries e suas obras com informações de posicionamento
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

-- Consulta 6: Usuários que completaram o desafio de leitura anual (leram 12 livros em um ano)
SELECT u.first_name,
	u.last_name,
	EXTRACT(
		YEAR
		FROM UPPER(t.reading_period)
	) as reading_year,
	COUNT(*) as books_read,
	AVG(t.rating) as avg_rating,
	SUM(e.page_count) as total_pages
FROM users u
	JOIN trackings t ON u.id = t.user_id
	JOIN editions e ON t.edition_id = e.id
WHERE t.status = 'read'
	AND t.reading_period IS NOT NULL
GROUP BY u.id,
	u.first_name,
	u.last_name,
	EXTRACT(
		YEAR
		FROM UPPER(t.reading_period)
	)
HAVING COUNT(*) >= 12
ORDER BY reading_year DESC,
	books_read DESC;

-- Consulta 7: Recomendação de livros baseada em gêneros favoritos dos usuários
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

-- Consulta 8: Livros lidos recentemente pelos usuários e suas avaliações
SELECT u.first_name,
	u.last_name,
	bd.work_title as book_title,
	bd.author_name,
	t.rating,
	t.review,
	UPPER(t.reading_period) as finish_date
FROM trackings t
	JOIN users u ON t.user_id = u.id
	JOIN book_details bd ON t.edition_id = bd.edition_id
WHERE t.status = 'read'
	AND t.reading_period IS NOT NULL
ORDER BY UPPER(t.reading_period) DESC;

-- Consulta 9: Progresso de leitura por formato de livro
SELECT e.format,
	COUNT(DISTINCT t.user_id) as unique_readers,
	COUNT(*) as total_trackings,
	AVG(t.progress) as avg_progress
FROM trackings t
	JOIN editions e ON t.edition_id = e.id
	JOIN users u ON t.user_id = u.id
GROUP BY e.format
ORDER BY total_trackings DESC;

-- Consulta 10: Estatísticas de leitura detalhadas por usuário
SELECT u.first_name,
	u.last_name,
	COUNT(DISTINCT t.edition_id) as total_books_read,
	AVG(t.rating) as avg_rating,
	SUM(e.page_count) as total_pages_read,
	COUNT(DISTINCT g.id) as genres_explored,
	MAX(UPPER(t.reading_period)) as last_book_finished,
	COUNT(
		CASE
			WHEN t.status = 'currently-reading' THEN 1
		END
	) as currently_reading
FROM users u
	LEFT JOIN trackings t ON u.id = t.user_id
	LEFT JOIN editions e ON t.edition_id = e.id
	LEFT JOIN works w ON e.work_id = w.id
	LEFT JOIN categorizations c ON w.id = c.work_id
	LEFT JOIN genres g ON c.genre_id = g.id
WHERE t.status IN ('read', 'currently-reading')
GROUP BY u.id,
	u.first_name,
	u.last_name
HAVING COUNT(DISTINCT t.edition_id) >= 1
ORDER BY total_books_read DESC;