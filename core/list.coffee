import {EventEmitter} from 'events'


export default _ = class List extends EventEmitter


	constructor: (Model, @selector = '', @vars = {})->
		super()
		Object.defineProperty @, 'Model', value: Model

		if @selector then @selector = "FILTER #{@selector}"
		@length = 0
		@size = 100
		@offset = 0
		@destroyed = false
		return



	destroy: ->
		if @destroyed then return
		@emit('destroy', @)
		@removeAllListeners()
		@destroyed = yes
		return



	next: ->
		@offset += @size
		await @update()
		return



	prev: ->
		@offset -= @size
		if @offset < 0 then @offset = 0
		await @update()
		return



	update: ->
		@vars.__OFFSET__ = @offset
		@vars.__SIZE__ = @size

		cursor = await @query "
			FOR this IN `#{@Model.name}`
				FILTER NOT this._removed
				#{@selector}
				LIMIT @__OFFSET__, @__SIZE__
				RETURN this
		", @vars

		documets = await cursor.all()
		models = @_toModels(documets)
		@_setModels(models)

		@emit('update', @)
		return



	query: (aql, vars)->
		return @Model.query(aql, vars)



	_toModels: (documets)->
		return documets.map (documet)=> @_toModel(documet)



	_toModel: (documet)->
		return @Model._toModel(documet)



	_setModels: (models)->
		Array::splice.call(@, 0, @length, models...)
		return


