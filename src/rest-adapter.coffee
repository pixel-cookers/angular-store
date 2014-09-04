'use strict'

###*
 # @ngdoc service
 # @name store.RESTAdapter
 # @description
 # # RESTAdapter
 # Service in the store.
###
angular

	.module('store.rest', [
		'store.rest.core'
		'store.rest.restangular'
	])

angular
	.module('store.rest.core', [
		'store.rest.restangular'
	])

	# TODO: inject pluralize
	.factory 'RESTAdapter', (RESTAdapterRestangular) ->

		# Return an array of all the records
		findAll = (type) ->
			RESTAdapterRestangular.all(pluralize(type)).getList()

		# Return an array of records filtered by the given query
		findQuery = (type, query) ->
			RESTAdapterRestangular.all(pluralize(type)).getList(query)

		# Return one record found by his `id` property
		findById = (type, id) ->
			RESTAdapterRestangular.one(pluralize(type), id).get()

		# Create a record
		createRecord = (type, record) ->
			console.log 'createRecord', type, record
			# TODO: createRecord

		# Delete a record
		deleteRecord = (type, record) ->
			console.log 'deleteRecord', type, record
			# TODO: deleteRecord

		class LocalForageAdapter
			constructor: ->

			findAll: (type) ->
				findAll(type)
			findByIds: (type, ids) ->
				findByIds(type, ids)
			findById: (type, id) ->
				findById(type, id)
			createRecord: (type, record) ->
				createRecord(type, record)
			deleteRecord: (type, record) ->
				deleteRecord(type, record)
