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
    'store.core.sanitizeRestangularOne'
  ])

  # TODO: inject pluralize
  .factory 'RESTAdapter', ($injector, $q, RESTAdapterRestangular, sanitizeRestangularOne) ->

    # Return an array of all the records
    findAll = (type, subResourceName) ->
      if subResourceName
        return RESTAdapterRestangular.all(pluralize(type)).all(subResourceName).getList()

      RESTAdapterRestangular.all(pluralize(type)).getList()

    # Return an array of records filtered by the given query
    findQuery = (type, query) ->
      RESTAdapterRestangular.all(pluralize(type)).getList(query)

    loadHasMany = (record, type) ->
      deferred = $q.defer()
      promises = {}

      # TODO: move this into a deserialize function ?
      for propertyName of sanitizeRestangularOne(record)
        if _.include(propertyName, '_ids')
          if record.originalResponse
            strippedPropertyName = propertyName.replace('_ids', '')
            pluralizedPropertyName = pluralize(strippedPropertyName)

            if record.originalResponse[pluralizedPropertyName]
              # record[pluralizedPropertyName] = record.originalResponse[pluralizedPropertyName]

              modelName = _.str.classify(strippedPropertyName) + 'Model'
              if $injector.has(modelName)
                model = $injector.get(modelName)

                records = _.map record.originalResponse[pluralizedPropertyName], (record) ->
                  new model(record, strippedPropertyName)

                record[pluralizedPropertyName] = records

      deferred.resolve(record)

      deferred.promise

    # Return one record found by his `id` property
    findById = (type, id) ->
      deferred = $q.defer()

      RESTAdapterRestangular
        .one(pluralize(type), id)
        .get()
        .then findOneSuccess = (record) ->
          if record
            loadHasMany(record, type).then (record) ->
              deferred.resolve(record)
          else
            deferred.reject('not_found')

        , findOneError = (error) ->
          deferred.reject(error)

      deferred.promise

    # Create a record
    createRecord = (type, record) ->
      console.error 'createRecord', type, record
      # TODO: createRecord

    # Delete a record
    deleteRecord = (type, record) ->
      console.error 'deleteRecord', type, record
      # TODO: deleteRecord

    class RESTAdapter
      constructor: ->

      findAll: (type, subResourceName) ->
        findAll(type, subResourceName)
      findByIds: (type, ids) ->
        findByIds(type, ids)
      findById: (type, id) ->
        findById(type, id)
      findQuery: (type, query) ->
        findQuery(type, query)
      createRecord: (type, record) ->
        createRecord(type, record)
      deleteRecord: (type, record) ->
        deleteRecord(type, record)
