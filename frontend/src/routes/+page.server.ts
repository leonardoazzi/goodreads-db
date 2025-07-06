import { API_URL } from '$lib/db';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch }) => {
	await fetch(`${API_URL}/api/v1/POST/consultas?query_id=view`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json'
		},
		body: JSON.stringify({})
	});
	await fetch(API_URL);
};
