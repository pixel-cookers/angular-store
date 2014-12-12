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
    'store.fileSystem.adapterCache'
    'ngCordova.plugins.file'
    'store.core.sanitizeRestangularOne'
  ])

  .value 'FileSystemAdapterMapping', []

  .factory 'FileSystemAdapterWriteDirectory', ->
    if cordova.file.documentsDirectory
      return cordova.file.documentsDirectory

    cordova.file.externalApplicationStorageDirectory

  # TODO: inject pluralize and lodash
  .factory 'FileSystemAdapter', ($rootScope, $q, $injector, $cordovaFile, sanitizeRestangularOne, FileSystemAdapterRestangular, FileSystemAdapterMapping, FileSystemAdapterWriteDirectory, FileSystemAdapterCache) ->

    broadcastNotFound = (error, type) ->
      $rootScope.$emit 'store.file_system.not_found', type
      'not_found'

    # Return an array of all the records
    findAll = (type, subResourceName) ->
      deferred = $q.defer()
      promises = []

      if subResourceName
        FileSystemAdapterRestangular
          .all(pluralize(type))
          .all(subResourceName)
          .getList(FileSystemAdapterCache.getAsParam())
          .then findAllSuccess = (records) ->
            deferred.resolve(deserialize(records, type))

          , findAllError = (error) ->
            deferred.reject(broadcastNotFound(error, type))

      else
        FileSystemAdapterRestangular
          .all(pluralize(type))
          .getList(FileSystemAdapterCache.getAsParam())
          .then findAllSuccess = (records) ->
            deferred.resolve(deserialize(records, type))

          , findAllError = (error) ->
            deferred.reject(broadcastNotFound(error, type))

      deferred.promise

    # Return an array of records filtered by the given query
    findQuery = (type, query) ->
      deferred = $q.defer()

      FileSystemAdapterRestangular
        .all(pluralize(type))
        .getList(FileSystemAdapterCache.getAsParam())
        .then (records) ->
          records = _.filter(records, query)

          if records
            deferred.resolve(records)
          else
            deferred.reject('not_found')

        , (error) ->
          deferred.reject(broadcastNotFound(error, type))

      deferred.promise

    # Return one record found by his `id` property
    findById = (type, id) ->
      deferred = $q.defer()
      record = null

      FileSystemAdapterRestangular
        .all(pluralize(type))
        .getList(FileSystemAdapterCache.getAsParam())
        .then (records) ->
          record = _.find(records, { id: id })

          if record
            loadHasMany(record, type).then (record) ->
              deferred.resolve(record)
          else
            deferred.reject('not_found')

        , (error) ->
          deferred.reject(broadcastNotFound(error, type))

      deferred.promise

    # Return an array of records filtered by id
    findByIds = (type, ids) ->
      modelName = _.str.classify(type) + 'Model'
      deferred = $q.defer()
      records = []

      FileSystemAdapterRestangular
        .all(pluralize(type))
        .getList(FileSystemAdapterCache.getAsParam())
        .then (records) ->
          records = _.where records, (record) ->
            _.contains(ids, record.id)

          deferred.resolve(records)

        , (error) ->
          deferred.reject(broadcastNotFound(error, type))

      deferred.promise

    loadHasMany = (record, type) ->
      deferred = $q.defer()
      promises = {}

      for propertyName of sanitizeRestangularOne(record)
        if _.include(propertyName, '_ids')
          addPromise = true
          pluralizedPropertyName = pluralize(propertyName.replace('_ids', ''))

          # hack to make sure that attachment_ids load media instead of attachments
          angular.forEach FileSystemAdapterMapping, (mapping) ->
            if pluralizedPropertyName is mapping.from
              promises['media'] = findByIds('media', record[propertyName])
              addPromise = false

          if addPromise
            promises[pluralizedPropertyName] = findByIds(propertyName.replace('_ids', ''), record[propertyName])

      $q.all(promises).then (relationships) ->
        for index of relationships
          record[index] = deserialize(relationships[index], pluralize(index, 1))

        deferred.resolve(record)

      deferred.promise

    # Return one record found by a specific property
    findBy = (type, propertyName, value) ->
      deferred = $q.defer()

      FileSystemAdapterRestangular
        .all(pluralize(type))
        .getList(FileSystemAdapterCache.getAsParam())
        .then (records) ->
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

        , (error) ->
          deferred.reject(broadcastNotFound(error, type))

      deferred.promise

    # Delete a record
    deleteRecord = (type, record, keys) ->
      deferred = $q.defer()

      # some records were found
      findAll(type).then findAllSuccess = (currentRecords) ->
        foundRecord = false
        newRecords = deserialize(currentRecords, type)

        if currentRecords.length > 0
          angular.forEach currentRecords, (currentRecord, index) ->
            # if we keys to use to find the record
            if keys
              if Array.isArray(keys)
                foundWithKey = false

                angular.forEach keys, (key) ->
                  if record[key] isnt currentRecord[key]
                    foundWithKey = false

                unless foundWithKey
                  foundRecord = true
                  delete newRecords[index]

              else
                # TODO: handle the case were keys is just a single value ?

            # if we don't, use the id attribute
            else
              if angular.isDefined(currentRecord.id) and record?.id is currentRecord.id
                delete newRecords[index]
                foundRecord = true

    # Save a record
    saveRecord = (type, record, keys) ->
      deferred = $q.defer()

      # some records were found
      findAll(type).then findAllSuccess = (currentRecords) ->
        foundRecord = false
        newRecords = deserialize(currentRecords, type)

        if currentRecords.length > 0
          angular.forEach currentRecords, (currentRecord, index) ->
            # if we keys to use to find the record
            if keys
              if Array.isArray(keys)
                foundWithKey = false

                angular.forEach keys, (key) ->
                  if record[key] isnt currentRecord[key]
                    foundWithKey = false

                unless foundWithKey
                  foundRecord = true
                  newRecords[index] = record

              else
                # TODO: handle the case were keys is just a single value ?

            # if we don't, use the id attribute
            else
              if angular.isDefined(currentRecord.id) and record?.id is currentRecord.id
                newRecords[index] = record
                foundRecord = true

        unless foundRecord
          newRecords.push record

        save(record.type, newRecords).then saveSuccess = ->
          deferred.resolve(record)

      # no records found or error
      , findAllError = (error) ->
        save(record.type, [record]).then saveSuccess = ->
          deferred.resolve(record)

      deferred.promise

    # Save all records for a given type
    save = (type, records) ->
      deferred = $q.defer()
      pluralizedType = pluralize(type)
      writeFileOptions = { 'append': false }

      # prepare the json object
      jsonRecords = {}
      jsonRecords[pluralizedType] = serialize(records)
      jsonRecords = JSON.stringify(jsonRecords)

      # TODO: make sure this does not crash the application when outside or a
      #       cordova application :s
      resolveLocalFileSystemURL FileSystemAdapterWriteDirectory, (result) ->
        # dirty trick to get relative path in cordova...
        relativePath = result.fullPath.substring(1)
        destination = "#{relativePath}resources/#{pluralizedType}.json"

        $cordovaFile.writeFile(destination, jsonRecords, writeFileOptions).then createFileSuccess = (result) ->
          deferred.resolve(records)

        , createFileError = (error) ->
          deferred.reject('could_not_write_file')

      , (error) ->
        deferred.reject('could_not_open_directory')

      deferred.promise

    # serialize a record or a collection of records
    serialize = (records) ->
      if Array.isArray(records)
        return _.map records, (record) ->
          serializeRecord(record)

      serializeRecord(records)

    # serialize a record to store it with the correct format
    serializeRecord = (record) ->
      for key, value of record
        if angular.isFunction(value)
          delete record[key]

        else
          record[_.str.underscored(key)] = value
          delete record[key]

      record

    # deserialize a record or a collection of records
    deserialize = (records, type) ->
      if Array.isArray(records)
        deserializedRecords = _.map records, (record) ->
          deserializeRecord(record, type)

        return deserializedRecords

      deserializeRecord(records, type)

    # deserialize a record to store it with the correct format
    deserializeRecord = (record, type) ->
      modelName = _.str.classify(type) + 'Model'

      unless $injector.has(modelName)
        console.error 'Invalid model', modelName, 'for type:', type
        return record

      model = $injector.get modelName
      new model(record, type)

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
      deleteRecord: (type, record, keys) ->
        deleteRecord(type, record, keys)
      saveRecord: (type, record, keys) ->
        saveRecord(type, record, keys)
      save: (type, records) ->
        save(type, records)
