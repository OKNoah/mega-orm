import FieldType from './field-type'
import FieldTypes from './field-types'
import FieldSchemas from './field-schemas'


export default _ = class Schema


	constructor: (obj, isRootSchema = yes)->
		@fields = @getFields(obj)

		if isRootSchema
			@fields.push new FieldType {type: String, internal: yes}, ['_id']
			@fields.push new FieldType {type: String, internal: yes}, ['_key']
			@fields.push new FieldType {type: String, internal: yes}, ['_rev']
			@fields.push new FieldType {type: Boolean, default: false}, ['_removed']
		return



	toDocument: (model)->
		document = {}
		for field in @fields
			field.toDocument(model, document)
		return document



	toModel: (document, model)->
		for field in @fields
			field.toModel(document, model)
		return model



	getFields: (value, fields = [], path = [])->
		if Array.isArray(value)

			if @isField(value[0])
				fields.push new FieldTypes(value[0], path)

			else
				schema = new Schema(value[0], off)
				fields.push new FieldSchemas(schema, path)

		else if @isField(value)
			fields.push new FieldType(value, path)

		else for own key, item of value
			@getFields(item, fields, path.concat(key))

		return fields



	isField: (value)->
		return typeof value?.type is 'function'

