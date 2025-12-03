const path = require('path')
const srcPath = path.join(process.cwd(), 'src')
const outputPath = path.join(process.cwd(), 'build')

// load the reusable legacy webpack config from materia-widget-dev
const wp = require('materia-widget-development-kit/webpack-widget')
const copy = wp.getDefaultCopyList()

const copyConfig = [
	...copy,
	{
		from: path.join(__dirname, 'src', '_guides', 'assets'),
		to: path.join(outputPath, 'guides', 'assets'),
		toType: 'dir'
	}
]

const entries = {
	'creator': [
		path.join(srcPath, 'creator.html'),
		path.join(srcPath, 'creator.scss'),
		path.join(srcPath, 'puzzle.coffee'),
		path.join(srcPath, 'creator.coffee')
	],
	'player': [
		path.join(srcPath, 'player.html'),
		path.join(srcPath, 'player.scss'),
		path.join(srcPath, 'puzzle.coffee'),
		path.join(srcPath, 'player.coffee')
	]
}

const options = {
	copyList: copyConfig,
	entries: entries
}

module.exports = wp.getLegacyWidgetBuildConfig(options)
