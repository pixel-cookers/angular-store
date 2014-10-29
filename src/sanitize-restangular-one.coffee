'use strict'

###*
 # @ngdoc factory
 # @name store.RESTAdapterRestangular
 # @description
 # # RESTAdapterRestangular
 # Factory in the store.
###
angular

  .module('store.core.sanitizeRestangularOne', [])

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
