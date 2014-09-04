'use strict'

###*
 # @ngdoc service
 # @name store.LocalForageAdapter
 # @description
 # # LocalForageAdapter
 # Service in the store.
###
angular.module('store.localForage', [
	'store.core'
	'LocalForageModule'
])

	.config ($localForageProvider) ->
		# localForage configuration
		$localForageProvider.config
			name: 'archeage_tools',
			storeName: 'archeage_tools'

	# TODO: doc and deps
	.factory 'LocalForageAdapter', ($q, $localForage) ->

		# Return an array of all the records
		findAll = (type) ->
			$localForage.getItem(type)

		# Return an array of records filtered by the given query
		findQuery = (type, query) ->
			console.log 'findQuery', query

		# Return an array of records filtered by their ids
		findByIds = (type, ids) ->
			deferred = $q.defer()
			promises = []

			_.each ids, (id) ->
				promises.push findById(type, id)

			$q.all(promises).then (records) ->
				deferred.resolve(records)

			deferred.promise

		# Return one record found by a specific property
		findBy = (type, object) ->
			deferred = $q.defer()

			$localForage.getItem(type).then (records) ->
				record = _.find(records, object)

				if record
					deferred.resolve(record)
				else
					deferred.reject('not_found')

			deferred.promise

		# Return one record found by his `id` property
		findById = (type, id) ->
			deferred = $q.defer()

			$localForage.getItem(type).then (records) ->
				record = _.find(records, { id: id })

				if record
					deferred.resolve(record)
				else
					deferred.reject('not_found')

			deferred.promise

		# Create a record
		createRecord = (type, record) ->
			deferred = $q.defer()

			$localForage.getItem(type).then (records) ->
				if not records
					records = []

				lastRecord = records[records.length - 1]

				if lastRecord
					record.id = lastRecord.id + 1
				else
					record.id = 1

				records.push(record)

				$localForage.setItem(type, records).then ->
					deferred.resolve(record)

			deferred.promise

		# Delete a record
		deleteRecord = (type, record) ->
			deferred = $q.defer()

			$localForage.getItem(type).then (records) ->
				filteredRecords = _.filter records, (r) ->
					r.id isnt record.id

				$localForage.setItem(type, filteredRecords).then ->
					deferred.resolve()

			deferred.promise

		# Save a record
		saveRecord = (type, record) ->
			deferred = $q.defer()

			if record.id
				$localForage.getItem(type).then (records) ->
					records = _.map records, (currentRecord) ->
						if currentRecord.id is record.id
							return record

						return currentRecord

					$localForage.setItem(type, records).then ->
						deferred.resolve(record)

				return deferred.promise

			createRecord(type, record)

		class LocalForageAdapter
			constructor: ->

			findAll: (type) ->
				findAll(type)
			findQuery: (type, query) ->
				findQuery(type, query)
			findByIds: (type, ids) ->
				findByIds(type, ids)
			findById: (type, id) ->
				findById(type, id)
			findBy: (type, object) ->
				findBy(type, object)
			createRecord: (type, record) ->
				createRecord(type, record)
			deleteRecord: (type, record) ->
				deleteRecord(type, record)
			saveRecord: (type, record) ->
				saveRecord(type, record)
