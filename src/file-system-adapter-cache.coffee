'use strict'

###*
 # @ngdoc factory
 # @name store.fileSystem.adapterCache
 # @description
 # # FileSystemAdapterCache
 # Service in store.fileSystem.
###
angular

  .module('store.fileSystem.adapterCache', [
    'restangular'
  ])

  .factory 'FileSystemAdapterCache', ->

    cacheString = null

    init = ->
      cacheString = Math.random()

    # get the current cache string
    get = ->
      cacheString

    # get the current cache string in an object used to pass as parameter for
    # api calls
    getAsParam = ->
      { 'v': cacheString }

    # generate a new cache string and return it
    pop = ->
      init()
      cacheString

    # init the service
    init()

    get: get
    getAsParam: getAsParam
    pop: pop
