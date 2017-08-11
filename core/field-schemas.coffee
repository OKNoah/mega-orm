export default _ = class FieldSchemas


	constructor: (@schema, @fullPath)->
		[@path..., @prop] = @fullPath
		return


	toDocument: (model, document)->
		value = @getByPath(model)
		value = @toDocumentValue(value)
		@setByPath(document, value)
		return



	toModel: (document, model)->
		value = @getByPath(document)
		value = @toModelValue(value)
		@setByPath(model, value)
		return



	toDocumentValue: (arr = [])->
		return arr.map (value)=> @schema.toDocument(value)



	toModelValue: (arr = [])->
		return arr.map (value)=> @schema.toModel(value, {})



	getByPath: (context)->
		for prop in @path
			unless context? then return
			context = context[prop]
		return context[@prop]



	setByPath: (context, value)->
		for prop in @path
			context = context[prop] ?= {}
		context[@prop] = value
		return


