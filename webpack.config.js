const path = require('path')
const srcPath = path.join(process.cwd(), 'src')
const outputPath = path.join(process.cwd(), 'build')

// load the reusable legacy webpack config from materia-widget-dev
const wp = require('materia-widget-development-kit/webpack-widget')
const entries = wp.getDefaultEntries()
const copy = wp.getDefaultCopyList()

const copyConfig = [
	...copy,
	{
		from: path.join(__dirname, 'src', '_guides', 'assets'),
		to: path.join(outputPath, 'guides', 'assets'),
		toType: 'dir'
	}
]

entries['puzzle.js'] = [path.join(srcPath, 'puzzle.coffee')]
entries['guides/creator.temp.html'] = [path.join(srcPath, '_guides','creator.md')]
entries['guides/player.temp.html'] = [path.join(srcPath, '_guides','player.md')]

const options = {
	copyList: copyConfig,
	entries: entries

}

module.exports = wp.getLegacyWidgetBuildConfig(options)
