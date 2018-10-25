const path = require('path')
const srcPath = path.join(process.cwd(), 'src')

// load the reusable legacy webpack config from materia-widget-dev
const wpc = require('materia-widget-development-kit/webpack-widget').getLegacyWidgetBuildConfig()

wpc.entry['puzzle.js'] = [path.join(srcPath, 'puzzle.coffee')]

module.exports = wpc
