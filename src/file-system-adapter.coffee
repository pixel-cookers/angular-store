'use strict'

###*
 # @ngdoc service
 # @name store.FileSystemAdapter
 # @description
 # # FileSystemAdapter
 # Service in the store.
###
angular

	.module('store.fileSystem', [
		'store.fileSystem.core'
		'store.fileSystem.restangular'
	])

angular
	.module('store.fileSystem.core', [
		'store.fileSystem.restangular'
	])

	# TODO: inject pluralize and lodash
	.factory 'FileSystemAdapter', ($q, FileSystemAdapterRestangular) ->

		# Return an array of all the records
		findAll = (type) ->
			FileSystemAdapterRestangular.all(pluralize(type)).getList()

		# Return an array of records filtered by the given query
		findQuery = (type, query) ->
			deferred = $q.defer()

			FileSystemAdapterRestangular.all(pluralize(type)).getList().then (records) ->
				record = _.find(records, query)

				if record
					deferred.resolve(record)
				else
					deferred.reject('not_found')

			deferred.promise

		# Return one record found by his `id` property
		findById = (type, id) ->
			deferred = $q.defer()

			FileSystemAdapterRestangular.all(pluralize(type)).getList().then (records) ->
				record = _.find(records, { id: id })

				if record
					deferred.resolve(record)
				else
					deferred.reject('not_found')

			deferred.promise

		# Return one record found by a specific property
		findBy = (type, propertyName, value) ->
			deferred = $q.defer()

			FileSystemAdapterRestangular.all(pluralize(type)).getList().then (records) ->
				if value instanceof Array
					record = _.find records, (filterRecord) ->
						_.isEqual(filterRecord[propertyName], value)

				else
					record = _.find records, (filterRecord) ->
						filterRecord[propertyName] is value

				if record
					deferred.resolve(record)
				else
					deferred.reject('not_found')

			deferred.promise

		# Create a record
		createRecord = (type, record) ->
			console.log 'createRecord', type, record
			# TODO: createRecord

		# Delete a record
		deleteRecord = (type, record) ->
			console.log 'deleteRecord', type, record
			# TODO: deleteRecord


		class FileSystemAdapter
			constructor: ->

			findAll: (type) ->
				findAll(type)
			findByIds: (type, ids) ->
				findByIds(type, ids)
			findById: (type, id) ->
				findById(type, id)
			findBy: (type, propertyName, value) ->
				findBy(type, propertyName, value)
			createRecord: (type, record) ->
				createRecord(type, record)
			deleteRecord: (type, record) ->
				deleteRecord(type, record)
