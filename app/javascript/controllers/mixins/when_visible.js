// Runs callback once element is on or near the screen, then when the browser is idle.
// A hidden element (display: none) never intersects, so its callback never runs.
export function whenVisible(element, callback) {
	let idleId;
	let timerId;
	const observer = new IntersectionObserver(
		(entries) => {
			if (!entries.some((entry) => entry.isIntersecting)) return;
			observer.disconnect();
			if ("requestIdleCallback" in window) {
				idleId = requestIdleCallback(callback, { timeout: 2000 });
			} else {
				timerId = setTimeout(callback, 200);
			}
		},
		{ rootMargin: "200px" },
	);
	observer.observe(element);

	return () => {
		observer.disconnect();
		if (idleId) cancelIdleCallback(idleId);
		if (timerId) clearTimeout(timerId);
	};
}
