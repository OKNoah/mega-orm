import DBModel from './core/model'


module.exports.connect = (options)->

	# create new class
	class Model extends DBModel
		@_setOptions(options)

	# apply plugins
	for plugin in options.use or []
		Model = plugin(Model) or Model

	return Model

