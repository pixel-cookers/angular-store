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
        # TODO: find a way to not repeat this every time
        adapterName = _.str.classify(type) + 'Adapter'

        unless $injector.has adapterName
          console.error 'invalid_adapter'

        adapterClass = $injector.get adapterName
        adapter = new adapterClass

        if arguments.length is 1
          return @findAll(type)

        if typeof(id) is 'object'
          return @findQuery(type, id)

        # cast the id into an integer if we can
        id = parseInt(id, 10) || id

        @findById(type, id)

      findAll: (type) ->
        deferred = $q.defer()

        modelName = _.str.classify(type) + 'Model'

        if $injector.has(modelName)
          model = $injector.get modelName

          adapter.findAll(type).then (records) ->
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

          adapterName = _.str.classify(type) + 'Adapter'

          if $injector.has(adapterName)
            adapterClass = $injector.get adapterName
            adapter = new adapterClass
            deferred = $q.defer()

            adapter.findByIds(type, ids).then (records) ->
              records = _.map records, (record) ->
                new model(record, type)

              deferred.resolve(records)

            , (error) ->
              deferred.reject(error)

          else
            deferred.reject('invalid_adapter')

        else
          deferred.reject('invalid_model')

        deferred.promise

      findBy: (type, propertyName, value) ->
        deferred = $q.defer()
        adapterName = _.str.classify(type) + 'Adapter'

        if $injector.has adapterName
          adapterClass = $injector.get adapterName
          adapter = new adapterClass

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

        else
          deferred.reject('invalid_adapter')

        deferred.promise

      findById: (type, id) ->
        unless id
          console.error 'id parameter required'

        deferred = $q.defer()
        adapterName = _.str.classify(type) + 'Adapter'

        if $injector.has(adapterName)
          adapterClass = $injector.get adapterName
          adapter = new adapterClass

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

        else
          deferred.reject('invalid_adapter')

        deferred.promise

      createRecord: (type, record) ->
        adapterName = _.str.classify(type) + 'Adapter'

        if $injector.has(adapterName)
          adapterClass = $injector.get adapterName
          adapter = new adapterClass
          adapter.createRecord(type, record)

        else
          console.error('invalid_adapter')

      # TODO: remove the type parameter since we can get it from the record
      deleteRecord: (type, record) ->
        adapterName = _.str.classify(type) + 'Adapter'

        if $injector.has(adapterName)
          adapterClass = $injector.get adapterName
          adapter = new adapterClass
          adapter.deleteRecord(type, record)

        else
          console.error('invalid_adapter')

      saveRecord: (record) ->
        className = record.constructor.name
        className = className.replace('Model', '')

        type = _.str.underscored(className)

        adapterName = "#{className}Adapter"

        if $injector.has(adapterName)
          adapterClass = $injector.get adapterName
          adapter = new adapterClass

          adapter.saveRecord(type, record)

        else
          console.error('invalid_adapter')

    return
