import FieldType from './field-type'
import ValidationError from './validation-error'


export default _ = class FieldTypes extends FieldType


	constructor: ->
		super(arguments...)
		@propModels = "_#{@prop}_models"
		return



	toDocumentValue: (arr = [])->
		@validateArr(arr)
		return arr.map (value)=> super(value)



	toModelValue: (arr = [])->
		return arr.map (value)=> super(value)



	getByPath: (context, contextIsModel)->
		for prop in @path
			unless context? then return
			context = context[prop]

		if contextIsModel
			if context[@propModels]
				return context[@propModels].map (model)=> @getId(model)

			if context[@propId]
				return context[@propId]

			descriptor = Object.getOwnPropertyDescriptor(context, @prop)
			unless descriptor then return
			if descriptor.get then return
			return context[@prop].map (model)=> @getId(model)

		return context[@prop]



	setter: (context, value)->
		context[@propModels] = value
		delete context[@propId]
		return



	getter: (context)->
		if context[@propModels]
			return context[@propModels]

		ids = context[@propId]
		models = await @type.get(ids)
		delete context[@propId]
		return context[@propModels] = models



	validateArr: (value)->
		unless Array.isArray(value)
			throw new ValidationError(ValidationError::TYPE, value, {type: Array})
		return



