export default _ = class ValidationError

	NULL: 0
	TYPE: 1
	RANGE: 2
	ENUM: 3


	constructor: (@code, @value, @options)->
		#		@name = 'ValidationError'
		return


