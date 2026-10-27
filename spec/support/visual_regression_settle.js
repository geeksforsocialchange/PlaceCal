export default async () => {
	const timeout = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
	await Promise.race([document.fonts.ready, timeout(10000)]);
	document.querySelectorAll("img[loading=lazy]").forEach((img) => {
		img.loading = "eager";
	});
	const images = [...document.images].filter((img) => !img.complete);
	await Promise.all(
		images.map(
			(img) =>
				new Promise((resolve) => {
					img.addEventListener("load", resolve, { once: true });
					img.addEventListener("error", resolve, { once: true });
					setTimeout(resolve, 5000);
				}),
		),
	);
	// CSS background images are not in document.images and can still be loading after a timed-out load event.
	const urls = new Set();
	for (const el of document.querySelectorAll("*")) {
		for (const pseudo of [null, "::before", "::after"]) {
			for (const match of getComputedStyle(el, pseudo).backgroundImage.matchAll(
				/url\("?([^")]+)"?\)/g,
			))
				urls.add(match[1]);
		}
	}
	await Promise.all(
		[...urls].map((url) =>
			Promise.race([
				new Promise((resolve) => {
					const img = new Image();
					img.onload = img.onerror = resolve;
					img.src = url;
				}),
				timeout(5000),
			]),
		),
	);
	await new Promise((resolve) =>
		requestAnimationFrame(() => requestAnimationFrame(resolve)),
	);
};
