'use strict'

angular

	.module('store', [
		'store.core'
		'store.localForage'
		'store.rest'
		'store.fileSystem'
	])

###*
 # @ngdoc provider
 # @name Store
 # @description
 # # Store
 # Provider in the Store.
###
angular

	.module('store.core', [])

	# TODO: inject lodash + underscore.string
	.provider 'Store', ->
		adapter = null
		adapterName = null

		@$get = ($injector, $q) ->

			new: (type) ->
				model = $injector.get(_.str.classify(type) + 'Model')
				deferred = $q.defer()

				deferred.resolve(new model(null, type))

				deferred.promise

			find: (type, id) ->
				# TODO: find a way to not repeat this every time
				adapterClass = $injector.get(_.str.classify(type) + 'Adapter')
				adapter = new adapterClass

				if arguments.length is 1
					return @findAll(type)

				if typeof(id) is 'object'
					return @findQuery(type, id)

				# cast the id into an integer if we can
				id = parseInt(id, 10) || id

				@findById(type, id)

			findAll: (type) ->
				model = $injector.get(_.str.classify(type) + 'Model')
				deferred = $q.defer()

				adapter.findAll(type).then (records) ->
					records = _.map records, (record) ->
						new model(record, type)

					deferred.resolve(records)

				deferred.promise

			findQuery: (type, query) ->
				model = $injector.get(_.str.classify(type) + 'Model')
				deferred = $q.defer()

				adapter.findQuery(type, query).then (records) ->
					records = _.map records, (record) ->
						new model(record, type)

					deferred.resolve(records)

				deferred.promise

			findByIds: (type, ids) ->
				if not ids
					console.error 'ids parameter required'

				model = $injector.get(_.str.classify(type) + 'Model')
				adapterClass = $injector.get(_.str.classify(type) + 'Adapter')
				adapter = new adapterClass
				deferred = $q.defer()

				adapter.findByIds(type, ids).then (records) ->
					records = _.map records, (record) ->
						new model(record, type)

					deferred.resolve(records)

				deferred.promise

			findBy: (type, propertyName, value) ->
				adapterClass = $injector.get(_.str.classify(type) + 'Adapter')
				adapter = new adapterClass
				deferred = $q.defer()

				adapter.findBy(type, propertyName, value).then (record) ->
					model = $injector.get(_.str.classify(type) + 'Model')
					record = new model(record, type)
					deferred.resolve(record)

				deferred.promise

			findById: (type, id) ->
				if not id
					console.error 'id parameter required'

				adapterClass = $injector.get(_.str.classify(type) + 'Adapter')
				adapter = new adapterClass
				deferred = $q.defer()

				adapter.findById(type, id).then (record) ->
					model = $injector.get(_.str.classify(type) + 'Model')
					record = new model(record, type)
					deferred.resolve(record)

				deferred.promise

			createRecord: (type, record) ->
				adapterClass = $injector.get(_.str.classify(type) + 'Adapter')
				adapter = new adapterClass
				adapter.createRecord(type, record)

			# TODO: remove the type parameter since we can get it from the record
			deleteRecord: (type, record) ->
				adapterClass = $injector.get(_.str.classify(type) + 'Adapter')
				adapter = new adapterClass
				adapter.deleteRecord(type, record)

			saveRecord: (record) ->
				className = record.constructor.name
				className = className.replace('Model', '')
				type = _.str.underscored(className)
				adapterClass = $injector.get("#{className}Adapter")
				adapter = new adapterClass

				adapter.saveRecord(type, record)

		return
