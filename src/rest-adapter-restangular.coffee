'use strict'

###*
 # @ngdoc factory
 # @name store.RESTAdapterRestangular
 # @description
 # # RESTAdapterRestangular
 # Service in the store.
###
angular

	.module('store.rest.restangular', [
		'restangular'
	])

  # TODO: inject pluralize
  .factory 'RESTAdapterRestangular', (Restangular) ->
    Restangular.withConfig (RestangularConfigurer) ->

      RestangularConfigurer.setBaseUrl('http://localhost:3000')
      RestangularConfigurer.setDefaultHttpFields({ cache: true })

      RestangularConfigurer.setResponseExtractor (data, operation, what, url, response) ->
        newResponse = data or {};

        if operation is 'getList'
          newResponse = data[what] if data and data[what]

        if operation is 'get'
          singularKey = pluralize(what, 1)

          if data and data[singularKey]
            newResponse = data[singularKey]

        newResponse.originalResponse = response.data

        newResponse
