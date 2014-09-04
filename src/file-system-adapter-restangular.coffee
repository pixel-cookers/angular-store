'use strict'

###*
 # @ngdoc factory
 # @name store.FileSystemAdapterRestangular
 # @description
 # # FileSystemAdapterRestangular
 # Service in the store.
###
angular

	.module('store.fileSystem.restangular', [
		'restangular'
	])

	# TODO: inject pluralize
	.factory 'FileSystemAdapterRestangular', (Restangular) ->

		Restangular.withConfig (RestangularConfigurer) ->

			RestangularConfigurer.setBaseUrl('http://localhost:9000/filesystem')
			RestangularConfigurer.setRequestSuffix('.json')
			RestangularConfigurer.setDefaultHttpFields({ cache: true })

			RestangularConfigurer.setResponseExtractor (data, operation, what, url, response) ->
				newResponse = data or {};

				if operation is 'getList'
					newResponse = data[what] if data and data[what]

				if operation is 'get'
					singularKey = pluralize(what, 1)
					if data and data[singularKey]
						newResponse = data[singularKey]

				newResponse
