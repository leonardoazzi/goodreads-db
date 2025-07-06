-- Consulta: Autores de sci-fi com nota maior que 4
SELECT DISTINCT a.*
FROM authors a
JOIN authorships au ON a.id = au.author_id
JOIN works w ON au.work_id = w.id
JOIN categorizations c ON w.id = c.work_id
JOIN genres g ON c.genre_id = g.id
WHERE g.slug = (%(genre)s) AND w.rating > %(rating)s;