/** @type {import('tailwindcss').Config} */
module.exports = {
	// Legacy v3 config - admin uses v4 CSS-first config in app/tailwind/
	prefix: "tw-",

	content: [
		"./app/views/**/*.{erb,html}",
		"./app/components/**/*.{erb,html,rb}",
		"./app/helpers/**/*.rb",
		"./app/javascript/**/*.{js,ts}",
		"./app/datatables/**/*.rb",
	],

	theme: {
		extend: {
			// PlaceCal brand colors
			colors: {
				placecal: {
					brown: "#5b4e46",
					cream: "#f5f1eb",
					orange: "#e87d1e",
					teal: "#00a9a5",
					pink: "#e91e63",
					purple: "#9c27b0",
				},
			},
			fontFamily: {
				sans: ["Lato", "system-ui", "sans-serif"],
			},
		},
	},

	plugins: [],
};
