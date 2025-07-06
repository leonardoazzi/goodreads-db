<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import * as Drawer from '$lib/components/ui/drawer';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import * as Table from '$lib/components/ui/table';
	import { runQuery } from '$lib/db';
	import queries from '$lib/queries.json';
	import { ChevronDownIcon } from 'lucide-svelte';
	import { expoOut } from 'svelte/easing';
	import { slide } from 'svelte/transition';

	let selectedQuery: (typeof queries)[number] | null = $state(queries[0]);
	let result: string[] | null = $state(null);
	let isDrawerOpen = $state(false);

	async function handleRunQuery(queryId: string, params?: (typeof queries)[number]['params']) {
		result = await runQuery(
			queryId,
			params?.reduce(
				(acc, param) => {
					acc[param.name] = param.value;
					return acc;
				},
				{} as Record<string, string | number>
			)
		);
		isDrawerOpen = true;
	}

	function handleSelect(queryId: string) {
		selectedQuery =
			queryId === selectedQuery?.queryId
				? null
				: (queries.find((query) => query.queryId === queryId) as (typeof queries)[number]);
	}
</script>

<div class="my-16 flex flex-col items-center gap-16 px-6">
	<h1 class="font-mono text-2xl">goodreads-db-viewer</h1>
	<div class=" w-full gap-2 {result ? 'grid-rows-2' : 'grid-rows-1'}">
		<div class="mx-auto flex w-full max-w-3xl flex-col gap-2">
			{#each queries as query (query.queryId)}
				{@const isOpen = selectedQuery?.queryId === query.queryId}
				<Card.Root class="gap-0 p-0">
					<button onclick={() => handleSelect(query.queryId)} class="p-6 text-left">
						<Card.Header class="p-0">
							<Card.Title>{query.title}</Card.Title>
							<Card.Description>{query.description}</Card.Description>
							<Card.Action class="flex h-full items-center">
								<ChevronDownIcon
									class="text-muted-foreground size-4 transition-all duration-400 {isOpen
										? 'rotate-180'
										: ''}"
								/>
							</Card.Action>
						</Card.Header>
					</button>
					{#if isOpen}
						<Card.Content>
							<div transition:slide={{ duration: 400, easing: expoOut }} class="grid">
								<div class="flex items-center gap-4 pb-6">
									{#if selectedQuery?.params}
										{#each selectedQuery.params as param}
											<div class="flex items-center gap-2">
												<Label for={param.name}>{param.name}</Label>
												<Input
													type={param.type}
													id={param.name}
													bind:value={param.value}
													class="max-w-32"
												/>
											</div>
										{/each}
									{/if}
									<Button onclick={() => handleRunQuery(query.queryId, selectedQuery?.params)}
										>Executar</Button
									>
								</div>
							</div>
						</Card.Content>
					{/if}
				</Card.Root>
			{/each}
		</div>
		<Drawer.Root bind:open={isDrawerOpen}>
			<Drawer.Content>
				{#if result}
					<Drawer.Header class="text-center">
						<Drawer.Title>{selectedQuery?.title}</Drawer.Title>
						<Drawer.Description>{selectedQuery?.description}</Drawer.Description>
					</Drawer.Header>
					<div class="flex flex-col justify-center overflow-y-auto pt-8 pb-12">
						{#if result.length > 0}
							<Table.Root class="mx-auto w-fit">
								<Table.Header>
									<Table.Row>
										{#each Object.keys(result[0]) as key}
											<Table.Head class="px-6">{key}</Table.Head>
										{/each}
									</Table.Row>
								</Table.Header>
								<Table.Body>
									{#each result as line (line)}
										<Table.Row>
											{#each Object.entries(line) as [key, value]}
												<Table.Cell class="px-6">{value}</Table.Cell>
											{/each}
										</Table.Row>
									{/each}
								</Table.Body>
							</Table.Root>
						{:else}
							<p class="text-muted-foreground/60 text-center text-sm">
								Nenhum resultado encontrado
							</p>
						{/if}
					</div>
				{/if}
			</Drawer.Content>
		</Drawer.Root>
	</div>
</div>
