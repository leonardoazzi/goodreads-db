import db from '$lib/server/db';
import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request }) => {
	const { query } = await request.json();
	const result = await db.query(query);
	return json(result.rows);
};
