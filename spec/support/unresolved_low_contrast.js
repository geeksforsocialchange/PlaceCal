export default async () => {
	const luminance = (colour) => {
		const [r, g, b] = colour
			.match(/[\d.]+/g)
			.slice(0, 3)
			.map((v) => {
				v /= 255;
				return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
			});
		return 0.2126 * r + 0.7152 * g + 0.0722 * b;
	};
	const fill = (el) => {
		for (; el; el = el.parentElement) {
			const bg = getComputedStyle(el).backgroundColor;
			if (bg !== "transparent" && !/, 0\)$/.test(bg)) return bg;
		}
		return "rgb(255, 255, 255)";
	};
	const { incomplete } = await axe.run(document, {
		runOnly: ["color-contrast"],
	});
	return incomplete
		.flatMap((rule) => rule.nodes)
		.filter((node) =>
			["bgImage", "bgOverlap"].includes(node.any[0]?.data?.messageKey),
		)
		.flatMap((node) => {
			const el = document.querySelector(node.target[0]);
			const style = getComputedStyle(el);
			const [a, b] = [luminance(style.color), luminance(fill(el))];
			const ratio = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
			const size = parseFloat(style.fontSize);
			const large =
				size >= 24 || (size >= 18.66 && parseInt(style.fontWeight, 10) >= 700);
			return ratio < (large ? 3 : 4.5)
				? [`${ratio.toFixed(2)}:1 ${style.color} on ${fill(el)}: ${node.html}`]
				: [];
		});
};
