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
  .provider 'Store', () ->

    configuration =
      adapterName: 'RESTAdapter'

    createService = ($injector, $q, config) ->

      adapter = null

      unless $injector.has config.adapterName
        console.error 'invalid_adapter'

      adapterClass = $injector.get config.adapterName
      adapter = new adapterClass

      service = {}

      service.withConfig = (config) ->
        newConfig = angular.copy(_.extend(configuration, config))

        createService($injector, $q, newConfig)

      service.new = (type, record) ->
        deferred = $q.defer()

        modelName = _.str.classify(type) + 'Model'

        if $injector.has(modelName)
          model = $injector.get modelName

          deferred.resolve(new model(record, type))

        else
          console.error 'Invalid model', modelName
          deferred.reject('invalid_model')

        deferred.promise

      service.getAdapter = ->
        adapter

      service.find = (type, id) ->

        # if the second argument is a string, this is probably a sub resource
        if typeof(id) is 'string' and not id.match(/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/)
          return @findAll(type, id)

        if arguments.length is 1
          return @findAll(type)

        if typeof(id) is 'object'
          return @findQuery(type, id)

        # cast the id into an integer if we can
        id = parseInt(id, 10) || id

        @findById(type, id)

      service.findAll = (type, subResourceName) ->
        adapter.findAll(type, subResourceName)

      service.findQuery = (type, query) ->
        deferred = $q.defer()

        modelName = _.str.classify(type) + 'Model'

        if $injector.has(modelName)
          model = $injector.get modelName

          adapter.findQuery(type, query).then (records) ->
            records = _.map records, (record) ->
              new model(record, type)

            deferred.resolve(records)

        else
          console.error 'Invalid model', modelName
          deferred.reject('invalid_model')

        deferred.promise

      service.findByIds = (type, ids) ->
        deferred = $q.defer()

        if not ids
          console.error 'ids parameter required'

        modelName = _.str.classify(type) + 'Model'

        if $injector.has(modelName)
          model = $injector.get(modelName)

          adapter.findByIds(type, ids).then (records) ->
            deferred.resolve(records)

          , (error) ->
            deferred.reject(error)

        else
          console.error 'Invalid model', modelName
          deferred.reject('invalid_model')

        deferred.promise

      service.findBy = (type, propertyName, value) ->
        deferred = $q.defer()

        adapter.findBy(type, propertyName, value).then (record) ->
          modelName = _.str.classify(type) + 'Model'

          if $injector.has(modelName)
            model = $injector.get modelName
            record = new model(record, type)

            deferred.resolve(record)

          else
            console.error 'Invalid model', modelName
            deferred.reject('invalid_model')

        , (error) ->
          deferred.reject(error)

        deferred.promise

      service.findById = (type, id) ->
        unless id
          console.error 'id parameter required'

        deferred = $q.defer()
        adapter.findById(type, id).then (record) ->
          modelName = _.str.classify(type) + 'Model'

          if $injector.has(modelName)
            model = $injector.get modelName
            record = new model(record, type)

            deferred.resolve(record)

          else
            console.error 'Invalid model', modelName
            deferred.reject('invalid_model')

        , (error) ->
          deferred.reject(error)

        deferred.promise

      service.createRecord = (type, record) ->
        adapter.createRecord(type, record)

      # TODO: remove the type parameter since we can get it from the record
      service.deleteRecord = (type, record) ->
        adapter.deleteRecord(type, record)

      service.saveRecord = (record) ->
        adapter.saveRecord(record.type, record)

      service

    @$get = ($injector, $q) ->
      createService($injector, $q, configuration)

    return
