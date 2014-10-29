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
  .provider 'Store', ($injector) ->

    @adapterName = 'RESTAdapter'

    @$get = ($injector, $q) ->
      unless $injector.has @adapterName
        return console.error 'invalid_adapter'

      adapterClass = $injector.get @adapterName
      adapter = new adapterClass

      new: (type, record) ->
        deferred = $q.defer()

        modelName = _.str.classify(type) + 'Model'

        if $injector.has(modelName)
          model = $injector.get modelName

          deferred.resolve(new model(record, type))

        else
          deferred.reject('invalid_model')

        deferred.promise

      find: (type, id) ->

        # if the second argument is a string, this is most probably a sub resource
        if typeof(id) is 'string' and not id.match(/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/)
          return @findAll(type, id)

        if arguments.length is 1
          return @findAll(type)

        if typeof(id) is 'object'
          return @findQuery(type, id)

        # cast the id into an integer if we can
        id = parseInt(id, 10) || id

        @findById(type, id)

      findAll: (type, subResourceName) ->
        deferred = $q.defer()

        modelName = _.str.classify(type) + 'Model'

        if $injector.has(modelName)
          model = $injector.get modelName

          adapter.findAll(type, subResourceName).then (records) ->
            records = _.map records, (record) ->
              new model(record, type)

            deferred.resolve(records)

          , (error) ->
            deferred.reject(error)

        else
          deferred.reject('invalid_model')

        deferred.promise

      findQuery: (type, query) ->
        deferred = $q.defer()

        modelName = _.str.classify(type) + 'Model'

        if $injector.has(modelName)
          model = $injector.get modelName

          adapter.findQuery(type, query).then (records) ->
            records = _.map records, (record) ->
              new model(record, type)

            deferred.resolve(records)

        else
          deferred.reject('invalid_model')

        deferred.promise

      findByIds: (type, ids) ->
        if not ids
          console.error 'ids parameter required'

        modelName = _.str.classify(type) + 'Model'

        if $injector.has(modelName)
          model = $injector.get(modelName)
          deferred = $q.defer()

          adapter.findByIds(type, ids).then (records) ->
            records = _.map records, (record) ->
              new model(record, type)

            deferred.resolve(records)

          , (error) ->
            deferred.reject(error)

        else
          deferred.reject('invalid_model')

        deferred.promise

      findBy: (type, propertyName, value) ->
        deferred = $q.defer()
        adapterName = _.str.classify(type) + 'Adapter'

        adapter.findBy(type, propertyName, value).then (record) ->
          modelName = _.str.classify(type) + 'Model'

          if $injector.has(modelName)
            model = $injector.get modelName
            record = new model(record, type)

            deferred.resolve(record)

          else
            deferred.reject('invalid_model')

        , (error) ->
          deferred.reject(error)

        deferred.promise

      findById: (type, id) ->
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
            deferred.reject('invalid_model')

        , (error) ->
          deferred.reject(error)

        deferred.promise

      createRecord: (type, record) ->
        adapter.createRecord(type, record)

      # TODO: remove the type parameter since we can get it from the record
      deleteRecord: (type, record) ->
        adapter.deleteRecord(type, record)

      saveRecord: (record) ->
        className = record.constructor.name
        className = className.replace('Model', '')

        type = _.str.underscored(className)

        adapter.saveRecord(type, record)

    return
