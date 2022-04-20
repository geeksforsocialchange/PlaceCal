const path = require('path')
const vuePlugin = require('esbuild-vue')

require("esbuild").build({
  entryPoints: ["application.js", "admin.js"],
  bundle: true,
  outdir: path.join(process.cwd(), "app/assets/builds"),
  absWorkingDir: path.join(process.cwd(), "app/javascript"),
  watch: process.argv.includes("--watch"),
  plugins: [vuePlugin()],
}).catch(() => process.exit(1))