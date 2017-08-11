import arangojs from 'arangojs'
import Schema from './schema'
import List from './list'


export default _ = class Model


	@isModel = yes
	@schema = null

	@_options = null
	@_dbCache = null
	@_collectionCache = null
	@_schemaCache = null


	@_setOptions: (opts = {})->
		@_options =
			db: opts.db   ? ''
			user: opts.user ? 'root'
			pass: opts.pass ? ''
			host: opts.host ? 'localhost'
			port: opts.port ? 8529
		return



	@_init: ->
		if @_dbCache then return

		{db: dbName, user, pass, host, port} = @_options
		db = arangojs(url: "http://#{user}:#{pass}@#{host}:#{port}")
		try await db.createDatabase(dbName)
		db.useDatabase(dbName)

		collection = db.collection(@name)
		try await collection.create()
		await this._setIndexes(collection)

		@_dbCache = db
		@_collectionCache = collection
		return



	@_setIndexes: (collection)->
		#		schema = this._getSchema()
		#
		#		for field in schema.fields
		#			path = field.fullPath.join('.')
		#			unique = field.options.unique
		#			try
		#				await collection.createHashIndex(path, {unique:false})
		#				console.log 'set', path
		return



	@_db: ->
		await @_init()
		return @_dbCache



	@_collection: ->
		await @_init()
		return @_collectionCache



	@_getSchema: ->
		return @_schemaCache ?= new Schema(@schema)



	@_escape: (value)->
		if (Object) isnt value then return value

		if value instanceof Array
			return value.map (item)=> @_escape(item)

		if value instanceof Model
			return value._id

		if value instanceof Date
			return value.getTime()

		obj = {}
		for own key, item of value
			obj[key] = @_escape(item)
		return obj



	@_toDocument: (model)->
		schema = @_getSchema()
		return schema.toDocument(model)



	@_toModel: (document)->
		schema = @_getSchema()
		model = new @()
		schema.toModel(document, model)
		return model



	@query: (aql, vars)->
		db = await @_db()
		vars = @_escape(vars)
		return await db.query(aql, vars)



	@select: (selector, vars)->
		list = new List(@, selector, vars)
		await list.update()
		return list



	@count: (selector, vars)->
		db = await @_db()
		if selector then selector = "FILTER #{selector}"

		aql = "FOR this IN `#{@name}`
				FILTER NOT this._removed
				#{selector}
				LIMIT 0
				RETURN this
		"
		cursor = await db.query(aql, vars, {options: {fullCount: on}})
		return cursor.extra.stats.fullCount



	@has: (selector, vars)->
		db = await @_db()
		if selector then selector = "FILTER #{selector}"

		aql = "FOR this IN `#{@name}`
				FILTER NOT this._removed
				#{selector}
				LIMIT 1
				RETURN this
		"
		cursor = await db.query(aql, vars, {count: on})
		return !!cursor.count



	@add: (model)->
		collection = await @_collection()
		document = @_toDocument(model)
		handle = await collection.save(document)
		for own key, value of handle
			document[key] = value
		return @_toModel(document)



	@get: (handle)->
		if Array.isArray(handle)
			cursor = await @query "RETURN DOCUMENT('#{@name}', #{@_escape(handle)})"
			documents = await cursor.next()
			return documents.map (document)=> @_toModel(document)

		collection = await @_collection()
		document = await collection.document(handle)
		return @_toModel(document)



	is: (model)->
		if typeof model is 'string'
			return @_id is model
		return @_id is model._id



	save: ->
		collection = await @constructor._collection()
		document = @constructor._toDocument(@)
		handle = await collection.update @_id, document, {mergeObjects: off}
		@_rev = handle._rev
		return @



	update: ->
		collection = await @constructor._collection()
		document = await collection.document(@_id)
		schema = @constructor._getSchema()
		schema.toModel(document, @)
		return @



	remove: ->
		@_removed = true
		return @save()



	restore: ->
		@_removed = false
		return @save()


#	removeLiterals = (code)->
#		regExp = /('|`|")((\\\1)|.)*?\1/g
#		literals = []
#		code = code.replace regExp, (match)=>
#			literals.push(match)
#			return "''"
#		return {code, literals}
#
#
#	restoreLiterals = ({code, literals})->
#		return code.replace /''/g, => literals.shift()
#
#
#	aql = "
#		@status is `lo is \` @ l`
#	"
#
#	res = removeLiterals(aql)
#	res.code = res.code.replace(/@\.?/g, 'this.')
#	res.code = res.code.replace(/\bis\b/g, '==')
#	aql = restoreLiterals(res)

