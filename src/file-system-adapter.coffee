'use strict'

###*
 # @ngdoc service
 # @name store.FileSystemAdapter
 # @description
 # # FileSystemAdapter
 # Service in the store.
###
angular

  .module('store.fileSystem', [
    'store.fileSystem.core'
    'store.fileSystem.restangular'
  ])

angular
  .module('store.fileSystem.core', [
    'store.fileSystem.restangular'
    'store.core.sanitizeRestangularOne'
  ])

  # TODO: inject pluralize and lodash
  .factory 'FileSystemAdapter', ($q, $injector, sanitizeRestangularOne, FileSystemAdapterRestangular) ->

    # Return an array of all the records
    findAll = (type, subResourceName) ->

      if subResourceName
        return FileSystemAdapterRestangular.all(pluralize(type)).all(subResourceName).getList()

      FileSystemAdapterRestangular.all(pluralize(type)).getList()

    # Return an array of records filtered by the given query
    findQuery = (type, query) ->
      deferred = $q.defer()

      FileSystemAdapterRestangular.all(pluralize(type)).getList().then (records) ->
        records = _.filter(records, query)

        if records
          deferred.resolve(records)
        else
          deferred.reject('not_found')

      deferred.promise

    # Return one record found by his `id` property
    findById = (type, id) ->
      deferred = $q.defer()
      record = null

      FileSystemAdapterRestangular.all(pluralize(type)).getList().then (records) ->
        record = _.find(records, { id: id })

        if record
          loadHasMany(record, type).then (record) ->
            deferred.resolve(record)
        else
          deferred.reject('not_found')

      deferred.promise

    # Return an array of records filtered by id
    findByIds = (type, ids) ->
      modelName = _.str.classify(type) + 'Model'
      deferred = $q.defer()
      records = []

      FileSystemAdapterRestangular.all(pluralize(type)).getList().then (records) ->
        records = _.where records, (record) ->
          _.contains(ids, record.id)

        if $injector.has(modelName)
          model = $injector.get(modelName)

          records = _.map records, (record) ->
            new model(record, type)

        deferred.resolve(records)

      deferred.promise

    loadHasMany = (record, type) ->
      deferred = $q.defer()
      promises = {}

      # TODO: do this into a separate function so we can choose to not side load relationships
      for propertyName of sanitizeRestangularOne(record)
        if _.include(propertyName, '_ids')
          pluralizedPropertyName = pluralize(propertyName.replace('_ids', ''))

          promises[pluralizedPropertyName] = findByIds(propertyName.replace('_ids', ''), record[propertyName])

      $q.all(promises).then (relationships) ->
        for index of relationships
          record[index] = relationships[index]

        deferred.resolve(record)

      deferred.promise

    # Return one record found by a specific property
    findBy = (type, propertyName, value) ->
      deferred = $q.defer()

      FileSystemAdapterRestangular.all(pluralize(type)).getList().then (records) ->
        if value instanceof Array
          record = _.find records, (filterRecord) ->
            _.isEqual(filterRecord[propertyName], value)

        else
          record = _.find records, (filterRecord) ->
            filterRecord[propertyName] is value

        if record
          deferred.resolve(record)
        else
          deferred.reject('not_found')

      deferred.promise

    # Create a record
    createRecord = (type, record) ->
      console.log 'createRecord', type, record
      # TODO: createRecord

    # Delete a record
    deleteRecord = (type, record) ->
      console.log 'deleteRecord', type, record
      # TODO: deleteRecord


    class FileSystemAdapter
      constructor: ->

      findAll: (type, subResourceName) ->
        findAll(type, subResourceName)
      findQuery: (type, query) ->
        findQuery(type, query)
      findByIds: (type, ids) ->
        findByIds(type, ids)
      findById: (type, id) ->
        findById(type, id)
      findBy: (type, propertyName, value) ->
        findBy(type, propertyName, value)
      createRecord: (type, record) ->
        createRecord(type, record)
      deleteRecord: (type, record) ->
        deleteRecord(type, record)
