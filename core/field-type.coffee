import ValidationError from './validation-error'
import Model from './model'


export default _ = class FieldType


	constructor: (@options, @fullPath)->
		[@path..., @prop] = @fullPath
		{@type} = @options
		@propId = "_#{@prop}"
		@isModel = @type.isModel

		# By default min strings length is 1
		# If the programmer wants to allow empty lines,
		# then he must explicitly specify
		if @type is String and not @options.min?
			@options.min = 1
		return



	toDocument: (model, document)->
		value = @getByPath(model, @isModel)
		value = @toDocumentValue(value)
		@setByPath(document, value)
		return



	toModel: (document, model)->
		value = @getByPath(document)
		value = @toModelValue(value)
		@setByPath(model, value, @isModel)
		return



	toDocumentValue: (value = @options.default)->
		# trim before validate
		value = @trimString(value)

		@validate(value)

		if @isModel
			return @getId(value)
		switch @type
			when Date then return value.getTime()
		return value



	toModelValue: (value)->
		if @isModel then return @getId(value)
		switch @type
			when Date then return new Date(value)
		return value



	getByPath: (context, contextIsModel)->
		for prop in @path
			unless context? then return
			context = context[prop]

		if contextIsModel
			if context[@propId]
				return context[@propId]

			descriptor = Object.getOwnPropertyDescriptor(context, @prop)
			unless descriptor then return
			if descriptor.get then return
			return context[@prop]


		return context[@prop]



	setByPath: (context, value, isModel)->
		for prop in @path
			context = context[prop] ?= {}

		unless isModel
			context[@prop] = value
			return

		context[@propId] = value
		if context.hasOwnProperty(@prop) then return
		Object.defineProperty context, @prop,
			enumerable: on
			set: (value)=> @setter(context, value)
			get: => @getter(context)
		return



	setter: (context, value)->
		context[@propId] = @getId(value)
		return



	getter: (context)->
		unless context[@propId] then return
		return @type.get(context[@propId])



	getId: (model)->
		unless model then return
		if Object(model) is model
			return model._id
		return model



	trimString: (value)->
		if (@type is String) and (@options.trim) and (typeof value is 'string')
			return value.trim()
		return value



	validate: (value)->
		if @options.internal then return
		if @options.null and value is undefined then return

		unless @checkNull(value)
			throw new ValidationError(ValidationError::NULL, value, @options)

		unless @checkType(value)
			throw new ValidationError(ValidationError::TYPE, value, @options)

		unless @checkRange(value)
			throw new ValidationError(ValidationError::RANGE, value, @options)

		unless @checkEnum(value)
			throw new ValidationError(ValidationError::ENUM, value, @options)
		return



	checkNull: (value)->
		if @options.null then return true
		return value?



	checkType: (value)->
		if @isModel
			return typeof value is 'string' or value instanceof @type

		return switch @type
			when Boolean then typeof value is 'boolean'
			when String then typeof value is 'string'
			when Number then typeof value is 'number'
			else
				value instanceof @type



	checkRange: (value)->
		if @type is Number
			if @options.min? and value < @options.min
				return false

			if @options.max? and value > @options.max
				return false

		if @type is String
			if @options.min? and value.length < @options.min
				return false

			if @options.max? and value.length > @options.max
				return false

			if @options.test? and not @options.test.test(value)
				return false

		return true



	checkEnum: (value)->
		unless @options.enum then return true
		return value in @options.enum




