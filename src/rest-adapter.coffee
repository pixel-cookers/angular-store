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

	 # Remove all Restangular/AngularJS added methods in order to use Jasmine toEqual between
	 # the retrieve resource and the model
	.factory 'sanitizeRestangularOne', () ->
  	(item) ->
    	_.omit item, 'route', 'parentResource', 'getList', 'get', 'post', 'put', 'remove', 'head',
    		'trace', 'options', 'patch', '$then', '$resolved', 'restangularCollection',
    		'customOperation', 'customGET', 'customPOST', 'customPUT', 'customDELETE', 'customGETLIST',
    		'$getList', '$resolved', 'restangularCollection', 'one', 'all', 'doGET', 'doPOST', 'doPUT',
    		'doDELETE', 'doGETLIST', 'addRestangularMethod', 'getRestangularUrl', 'several',
    		'getRequestedUrl', 'clone', 'reqParams', 'withHttpConfig', 'oneUrl', 'allUrl',
    		'getParentList', 'save', 'fromServer', 'plain', 'singleOne'

	# TODO: inject pluralize
	.factory 'RESTAdapter', (RESTAdapterRestangular, sanitizeRestangularOne, $q) ->

		# Return an array of all the records
		findAll = (type) ->
			RESTAdapterRestangular.all(pluralize(type)).getList()

		# Return an array of records filtered by the given query
		findQuery = (type, query) ->
			RESTAdapterRestangular.all(pluralize(type)).getList(query)

		# Return one record found by his `id` property
		findById = (type, id) ->
			deferred = $q.defer()

			RESTAdapterRestangular.one(pluralize(type), id).get().then (record) ->

				# TODO: do this into a separate function so we can choose to not side load relationships
				for propertyName of sanitizeRestangularOne(record)
					if _.include(propertyName, '_ids')
						if record.originalResponse
							pluralizedPropertyName = pluralize(propertyName.replace('_ids', ''))

							if record.originalResponse[pluralizedPropertyName]
								record[pluralizedPropertyName] = record.originalResponse[pluralizedPropertyName]

				deferred.resolve(record)

			deferred.promise

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
