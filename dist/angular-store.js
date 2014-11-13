(function() {
  'use strict';

  /**
    * @ngdoc factory
    * @name store.fileSystem.adapterCache
    * @description
    * # FileSystemAdapterCache
    * Service in store.fileSystem.
   */
  angular.module('store.fileSystem.adapterCache', ['restangular']).factory('FileSystemAdapterCache', function() {
    var cacheString, get, getAsParam, init, pop;
    cacheString = null;
    init = function() {
      return cacheString = Math.random();
    };
    get = function() {
      return cacheString;
    };
    getAsParam = function() {
      return {
        'v': cacheString
      };
    };
    pop = function() {
      init();
      return cacheString;
    };
    init();
    return {
      get: get,
      getAsParam: getAsParam,
      pop: pop
    };
  });

}).call(this);

//# sourceMappingURL=file-system-adapter-cache.js.map
;(function() {
  'use strict';

  /**
    * @ngdoc factory
    * @name store.FileSystemAdapterRestangular
    * @description
    * # FileSystemAdapterRestangular
    * Service in the store.
   */
  angular.module('store.fileSystem.restangular', ['restangular']).factory('FileSystemAdapterRestangular', function(Restangular) {
    return Restangular.withConfig(function(RestangularConfigurer) {
      RestangularConfigurer.setBaseUrl('http://localhost:9000/filesystem');
      RestangularConfigurer.setRequestSuffix('.json');
      RestangularConfigurer.setDefaultHttpFields({
        cache: true
      });
      return RestangularConfigurer.setResponseExtractor(function(data, operation, what, url, response) {
        var newResponse, singularKey;
        newResponse = data || {};
        if (operation === 'getList') {
          if (data && data[what]) {
            newResponse = data[what];
          }
        }
        if (operation === 'get') {
          singularKey = pluralize(what, 1);
          if (data && data[singularKey]) {
            newResponse = data[singularKey];
          }
        }
        return newResponse;
      });
    });
  });

}).call(this);

//# sourceMappingURL=file-system-adapter-restangular.js.map
;(function() {
  'use strict';

  /**
    * @ngdoc service
    * @name store.FileSystemAdapter
    * @description
    * # FileSystemAdapter
    * Service in the store.
   */
  angular.module('store.fileSystem', ['store.fileSystem.core', 'store.fileSystem.restangular']);

  angular.module('store.fileSystem.core', ['store.fileSystem.restangular', 'store.fileSystem.adapterCache', 'ngCordova.plugins.file', 'store.core.sanitizeRestangularOne']).value('FileSystemAdapterMapping', []).factory('FileSystemAdapterWriteDirectory', function() {
    if (cordova.file.documentsDirectory) {
      return cordova.file.documentsDirectory;
    }
    return cordova.file.externalApplicationStorageDirectory;
  }).factory('FileSystemAdapter', function($rootScope, $q, $injector, $cordovaFile, sanitizeRestangularOne, FileSystemAdapterRestangular, FileSystemAdapterMapping, FileSystemAdapterWriteDirectory, FileSystemAdapterCache) {
    var FileSystemAdapter, broadcastNotFound, createRecord, deleteRecord, deserialize, deserializeRecord, findAll, findBy, findById, findByIds, findQuery, loadHasMany, save, saveRecord, serialize, serializeRecord;
    broadcastNotFound = function(error, type) {
      $rootScope.$emit('store.file_system.not_found', type);
      return 'not_found';
    };
    findAll = function(type, subResourceName) {
      var deferred, findAllError, findAllSuccess, promises;
      deferred = $q.defer();
      promises = [];
      if (subResourceName) {
        FileSystemAdapterRestangular.all(pluralize(type)).all(subResourceName).getList(FileSystemAdapterCache.getAsParam()).then(findAllSuccess = function(records) {
          return deferred.resolve(deserialize(records, type));
        }, findAllError = function(error) {
          return deferred.reject(broadcastNotFound(error, type));
        });
      } else {
        FileSystemAdapterRestangular.all(pluralize(type)).getList(FileSystemAdapterCache.getAsParam()).then(findAllSuccess = function(records) {
          return deferred.resolve(deserialize(records, type));
        }, findAllError = function(error) {
          return deferred.reject(broadcastNotFound(error, type));
        });
      }
      return deferred.promise;
    };
    findQuery = function(type, query) {
      var deferred;
      deferred = $q.defer();
      FileSystemAdapterRestangular.all(pluralize(type)).getList(FileSystemAdapterCache.getAsParam()).then(function(records) {
        records = _.filter(records, query);
        if (records) {
          return deferred.resolve(records);
        } else {
          return deferred.reject('not_found');
        }
      }, function(error) {
        return deferred.reject(broadcastNotFound(error, type));
      });
      return deferred.promise;
    };
    findById = function(type, id) {
      var deferred, record;
      deferred = $q.defer();
      record = null;
      FileSystemAdapterRestangular.all(pluralize(type)).getList(FileSystemAdapterCache.getAsParam()).then(function(records) {
        record = _.find(records, {
          id: id
        });
        if (record) {
          return loadHasMany(record, type).then(function(record) {
            return deferred.resolve(record);
          });
        } else {
          return deferred.reject('not_found');
        }
      }, function(error) {
        return deferred.reject(broadcastNotFound(error, type));
      });
      return deferred.promise;
    };
    findByIds = function(type, ids) {
      var deferred, modelName, records;
      modelName = _.str.classify(type) + 'Model';
      deferred = $q.defer();
      records = [];
      FileSystemAdapterRestangular.all(pluralize(type)).getList(FileSystemAdapterCache.getAsParam()).then(function(records) {
        records = _.where(records, function(record) {
          return _.contains(ids, record.id);
        });
        return deferred.resolve(records);
      }, function(error) {
        return deferred.reject(broadcastNotFound(error, type));
      });
      return deferred.promise;
    };
    loadHasMany = function(record, type) {
      var addPromise, deferred, pluralizedPropertyName, promises, propertyName;
      deferred = $q.defer();
      promises = {};
      for (propertyName in sanitizeRestangularOne(record)) {
        if (_.include(propertyName, '_ids')) {
          addPromise = true;
          pluralizedPropertyName = pluralize(propertyName.replace('_ids', ''));
          angular.forEach(FileSystemAdapterMapping, function(mapping) {
            if (pluralizedPropertyName === mapping.from) {
              promises['media'] = findByIds('media', record[propertyName]);
              return addPromise = false;
            }
          });
          if (addPromise) {
            promises[pluralizedPropertyName] = findByIds(propertyName.replace('_ids', ''), record[propertyName]);
          }
        }
      }
      $q.all(promises).then(function(relationships) {
        var index;
        for (index in relationships) {
          record[index] = deserialize(relationships[index], pluralize(index, 1));
        }
        return deferred.resolve(record);
      });
      return deferred.promise;
    };
    findBy = function(type, propertyName, value) {
      var deferred;
      deferred = $q.defer();
      FileSystemAdapterRestangular.all(pluralize(type)).getList(FileSystemAdapterCache.getAsParam()).then(function(records) {
        var record;
        if (value instanceof Array) {
          record = _.find(records, function(filterRecord) {
            return _.isEqual(filterRecord[propertyName], value);
          });
        } else {
          record = _.find(records, function(filterRecord) {
            return filterRecord[propertyName] === value;
          });
        }
        if (record) {
          return deferred.resolve(record);
        } else {
          return deferred.reject('not_found');
        }
      }, function(error) {
        return deferred.reject(broadcastNotFound(error, type));
      });
      return deferred.promise;
    };
    createRecord = function(type, record) {};
    deleteRecord = function(type, record) {};
    saveRecord = function(type, record) {
      var deferred, findAllError, findAllSuccess;
      deferred = $q.defer();
      findAll(type).then(findAllSuccess = function(currentRecords) {
        var foundRecord, newRecords, saveSuccess;
        foundRecord = false;
        newRecords = deserialize(currentRecords, type);
        if (currentRecords.length > 0) {
          angular.forEach(currentRecords, function(currentRecord, index) {
            if (angular.isDefined(currentRecord.id) && (record != null ? record.id : void 0) === currentRecord.id) {
              newRecords[index] = record;
              return foundRecord = true;
            }
          });
        }
        if (!foundRecord) {
          newRecords.push(record);
        }
        return save(record.type, newRecords).then(saveSuccess = function() {
          return deferred.resolve(record);
        });
      }, findAllError = function() {
        var saveSuccess;
        return save(record.type, [record]).then(saveSuccess = function() {
          return deferred.resolve(record);
        });
      });
      return deferred.promise;
    };
    save = function(type, records) {
      var deferred, jsonRecords, pluralizedType, writeFileOptions;
      deferred = $q.defer();
      pluralizedType = pluralize(type);
      writeFileOptions = {
        'append': false
      };
      jsonRecords = {};
      jsonRecords[pluralizedType] = serialize(records);
      jsonRecords = JSON.stringify(jsonRecords);
      resolveLocalFileSystemURL(FileSystemAdapterWriteDirectory, function(result) {
        var createFileError, createFileSuccess, destination, relativePath;
        relativePath = result.fullPath.substring(1);
        destination = "" + relativePath + pluralizedType + ".json";
        return $cordovaFile.writeFile(destination, jsonRecords, writeFileOptions).then(createFileSuccess = function(result) {
          return deferred.resolve(records);
        }, createFileError = function(error) {
          return deferred.reject('could_not_write_file');
        });
      }, function(error) {
        return deferred.reject('could_not_open_directory');
      });
      return deferred.promise;
    };
    serialize = function(records) {
      if (Array.isArray(records)) {
        return _.map(records, function(record) {
          return serializeRecord(record);
        });
      }
      return serializeRecord(records);
    };
    serializeRecord = function(record) {
      var key, value;
      for (key in record) {
        value = record[key];
        if (angular.isFunction(value)) {
          delete record[key];
        } else {
          record[_.str.underscored(key)] = value;
          delete record[key];
        }
      }
      return record;
    };
    deserialize = function(records, type) {
      var deserializedRecords;
      if (Array.isArray(records)) {
        deserializedRecords = _.map(records, function(record) {
          return deserializeRecord(record, type);
        });
        return deserializedRecords;
      }
      return deserializeRecord(records, type);
    };
    deserializeRecord = function(record, type) {
      var model, modelName;
      modelName = _.str.classify(type) + 'Model';
      if (!$injector.has(modelName)) {
        console.error('Invalid model', modelName, 'for type:', type);
        return record;
      }
      model = $injector.get(modelName);
      return new model(record, type);
    };
    return FileSystemAdapter = (function() {
      function FileSystemAdapter() {}

      FileSystemAdapter.prototype.findAll = function(type, subResourceName) {
        return findAll(type, subResourceName);
      };

      FileSystemAdapter.prototype.findQuery = function(type, query) {
        return findQuery(type, query);
      };

      FileSystemAdapter.prototype.findByIds = function(type, ids) {
        return findByIds(type, ids);
      };

      FileSystemAdapter.prototype.findById = function(type, id) {
        return findById(type, id);
      };

      FileSystemAdapter.prototype.findBy = function(type, propertyName, value) {
        return findBy(type, propertyName, value);
      };

      FileSystemAdapter.prototype.createRecord = function(type, record) {
        return createRecord(type, record);
      };

      FileSystemAdapter.prototype.deleteRecord = function(type, record) {
        return deleteRecord(type, record);
      };

      FileSystemAdapter.prototype.saveRecord = function(type, record) {
        return saveRecord(type, record);
      };

      FileSystemAdapter.prototype.save = function(type, records) {
        return save(type, records);
      };

      return FileSystemAdapter;

    })();
  });

}).call(this);

//# sourceMappingURL=file-system-adapter.js.map
;(function() {
  'use strict';

  /**
    * @ngdoc service
    * @name store.LocalForageAdapter
    * @description
    * # LocalForageAdapter
    * Service in the store.
   */
  angular.module('store.localForage', ['store.core', 'LocalForageModule']).config(function($localForageProvider) {
    return $localForageProvider.config({
      name: 'archeage_tools',
      storeName: 'archeage_tools'
    });
  }).factory('LocalForageAdapter', function($q, $localForage) {
    var LocalForageAdapter, createRecord, deleteRecord, findAll, findBy, findById, findByIds, findQuery, saveRecord;
    findAll = function(type) {
      return $localForage.getItem(type);
    };
    findQuery = function(type, query) {
      var deferred;
      deferred = $q.defer();
      $localForage.getItem(type).then(function(records) {
        var filteredRecords;
        filteredRecords = _.filter(records, query);
        if (filteredRecords) {
          return deferred.resolve(filteredRecords);
        } else {
          return deferred.reject('not_found');
        }
      });
      return deferred.promise;
    };
    findByIds = function(type, ids) {
      var deferred, promises;
      deferred = $q.defer();
      promises = [];
      _.each(ids, function(id) {
        return promises.push(findById(type, id));
      });
      $q.all(promises).then(function(records) {
        return deferred.resolve(records);
      });
      return deferred.promise;
    };
    findBy = function(type, object) {
      var deferred;
      deferred = $q.defer();
      $localForage.getItem(type).then(function(records) {
        var record;
        record = _.find(records, object);
        if (record) {
          return deferred.resolve(record);
        } else {
          return deferred.reject('not_found');
        }
      });
      return deferred.promise;
    };
    findById = function(type, id) {
      var deferred;
      deferred = $q.defer();
      $localForage.getItem(type).then(function(records) {
        var record;
        record = _.find(records, {
          id: id
        });
        if (record) {
          return deferred.resolve(record);
        } else {
          return deferred.reject('not_found');
        }
      });
      return deferred.promise;
    };
    createRecord = function(type, record) {
      var deferred;
      deferred = $q.defer();
      $localForage.getItem(type).then(function(records) {
        var lastRecord;
        if (!records) {
          records = [];
        }
        lastRecord = records[records.length - 1];
        if (lastRecord) {
          record.id = lastRecord.id + 1;
        } else {
          record.id = 1;
        }
        records.push(record);
        return $localForage.setItem(type, records).then(function() {
          return deferred.resolve(record);
        });
      });
      return deferred.promise;
    };
    deleteRecord = function(type, record) {
      var deferred;
      deferred = $q.defer();
      $localForage.getItem(type).then(function(records) {
        var filteredRecords;
        filteredRecords = _.filter(records, function(r) {
          return r.id !== record.id;
        });
        return $localForage.setItem(type, filteredRecords).then(function() {
          return deferred.resolve();
        });
      });
      return deferred.promise;
    };
    saveRecord = function(type, record) {
      var deferred;
      deferred = $q.defer();
      if (record.id) {
        $localForage.getItem(type).then(function(records) {
          records = _.map(records, function(currentRecord) {
            if (currentRecord.id === record.id) {
              return record;
            }
            return currentRecord;
          });
          return $localForage.setItem(type, records).then(function() {
            return deferred.resolve(record);
          });
        });
        return deferred.promise;
      }
      return createRecord(type, record);
    };
    return LocalForageAdapter = (function() {
      function LocalForageAdapter() {}

      LocalForageAdapter.prototype.findAll = function(type) {
        return findAll(type);
      };

      LocalForageAdapter.prototype.findQuery = function(type, query) {
        return findQuery(type, query);
      };

      LocalForageAdapter.prototype.findByIds = function(type, ids) {
        return findByIds(type, ids);
      };

      LocalForageAdapter.prototype.findById = function(type, id) {
        return findById(type, id);
      };

      LocalForageAdapter.prototype.findBy = function(type, object) {
        return findBy(type, object);
      };

      LocalForageAdapter.prototype.createRecord = function(type, record) {
        return createRecord(type, record);
      };

      LocalForageAdapter.prototype.deleteRecord = function(type, record) {
        return deleteRecord(type, record);
      };

      LocalForageAdapter.prototype.saveRecord = function(type, record) {
        return saveRecord(type, record);
      };

      return LocalForageAdapter;

    })();
  });

}).call(this);

//# sourceMappingURL=local-forage-adapter.js.map
;(function() {
  'use strict';

  /**
    * @ngdoc factory
    * @name store.RESTAdapterRestangular
    * @description
    * # RESTAdapterRestangular
    * Service in the store.
   */
  angular.module('store.rest.restangular', ['restangular']).factory('RESTAdapterRestangular', function(Restangular) {
    return Restangular.withConfig(function(RestangularConfigurer) {
      RestangularConfigurer.setBaseUrl('http://localhost:3000');
      RestangularConfigurer.setDefaultHttpFields({
        cache: true
      });
      return RestangularConfigurer.setResponseExtractor(function(data, operation, what, url, response) {
        var newResponse, singularKey;
        newResponse = data || {};
        if (operation === 'getList') {
          if (data && data[what]) {
            newResponse = data[what];
          }
        }
        if (operation === 'get') {
          singularKey = pluralize(what, 1);
          if (data && data[singularKey]) {
            newResponse = data[singularKey];
          }
        }
        newResponse.originalResponse = response.data;
        return newResponse;
      });
    });
  });

}).call(this);

//# sourceMappingURL=rest-adapter-restangular.js.map
;(function() {
  'use strict';

  /**
    * @ngdoc service
    * @name store.RESTAdapter
    * @description
    * # RESTAdapter
    * Service in the store.
   */
  angular.module('store.rest', ['store.rest.core', 'store.rest.restangular']);

  angular.module('store.rest.core', ['store.rest.restangular', 'store.core.sanitizeRestangularOne']).factory('RESTAdapter', function($injector, $q, RESTAdapterRestangular, sanitizeRestangularOne) {
    var RESTAdapter, createRecord, deleteRecord, findAll, findById, findQuery, loadHasMany;
    findAll = function(type, subResourceName) {
      var deferred, error, model, modelName, success;
      deferred = $q.defer();
      modelName = _.str.classify(type) + 'Model';
      if ($injector.has(modelName)) {
        model = $injector.get(modelName);
        if (subResourceName) {
          RESTAdapterRestangular.all(pluralize(type)).all(subResourceName).getList().then(success = function(records) {
            records = _.map(records, function(record) {
              return new model(record, type);
            });
            return deferred.resolve(records);
          }, error = function(error) {
            return deferred.reject(error);
          });
        } else {
          RESTAdapterRestangular.all(pluralize(type)).getList().then(success = function(records) {
            records = _.map(records, function(record) {
              return new model(record, type);
            });
            return deferred.resolve(records);
          }, error = function(error) {
            return deferred.reject(error);
          });
        }
      } else {
        console.error('Invalid model', modelName);
        deferred.reject('invalid_model');
      }
      return deferred.promise;
    };
    findQuery = function(type, query) {
      return RESTAdapterRestangular.all(pluralize(type)).getList(query);
    };
    loadHasMany = function(record, type) {
      var deferred, model, modelName, pluralizedPropertyName, promises, propertyName, records, strippedPropertyName;
      deferred = $q.defer();
      promises = {};
      for (propertyName in sanitizeRestangularOne(record)) {
        if (_.include(propertyName, '_ids')) {
          if (record.originalResponse) {
            strippedPropertyName = propertyName.replace('_ids', '');
            pluralizedPropertyName = pluralize(strippedPropertyName);
            if (record.originalResponse[pluralizedPropertyName]) {
              modelName = _.str.classify(strippedPropertyName) + 'Model';
              if ($injector.has(modelName)) {
                model = $injector.get(modelName);
                records = _.map(record.originalResponse[pluralizedPropertyName], function(record) {
                  return new model(record, strippedPropertyName);
                });
                record[pluralizedPropertyName] = records;
              }
            }
          }
        }
      }
      deferred.resolve(record);
      return deferred.promise;
    };
    findById = function(type, id) {
      var deferred, findOneError, findOneSuccess;
      deferred = $q.defer();
      RESTAdapterRestangular.one(pluralize(type), id).get().then(findOneSuccess = function(record) {
        if (record) {
          return loadHasMany(record, type).then(function(record) {
            return deferred.resolve(record);
          });
        } else {
          return deferred.reject('not_found');
        }
      }, findOneError = function(error) {
        return deferred.reject(error);
      });
      return deferred.promise;
    };
    createRecord = function(type, record) {
      return console.error('createRecord', type, record);
    };
    deleteRecord = function(type, record) {
      return console.error('deleteRecord', type, record);
    };
    return RESTAdapter = (function() {
      function RESTAdapter() {}

      RESTAdapter.prototype.findAll = function(type, subResourceName) {
        return findAll(type, subResourceName);
      };

      RESTAdapter.prototype.findByIds = function(type, ids) {
        return findByIds(type, ids);
      };

      RESTAdapter.prototype.findById = function(type, id) {
        return findById(type, id);
      };

      RESTAdapter.prototype.findQuery = function(type, query) {
        return findQuery(type, query);
      };

      RESTAdapter.prototype.createRecord = function(type, record) {
        return createRecord(type, record);
      };

      RESTAdapter.prototype.deleteRecord = function(type, record) {
        return deleteRecord(type, record);
      };

      return RESTAdapter;

    })();
  });

}).call(this);

//# sourceMappingURL=rest-adapter.js.map
;(function() {
  'use strict';

  /**
    * @ngdoc factory
    * @name store.RESTAdapterRestangular
    * @description
    * # RESTAdapterRestangular
    * Factory in the store.
   */
  angular.module('store.core.sanitizeRestangularOne', []).factory('sanitizeRestangularOne', function() {
    return function(item) {
      return _.omit(item, 'route', 'parentResource', 'getList', 'get', 'post', 'put', 'remove', 'head', 'trace', 'options', 'patch', '$then', '$resolved', 'restangularCollection', 'customOperation', 'customGET', 'customPOST', 'customPUT', 'customDELETE', 'customGETLIST', '$getList', '$resolved', 'restangularCollection', 'one', 'all', 'doGET', 'doPOST', 'doPUT', 'doDELETE', 'doGETLIST', 'addRestangularMethod', 'getRestangularUrl', 'several', 'getRequestedUrl', 'clone', 'reqParams', 'withHttpConfig', 'oneUrl', 'allUrl', 'getParentList', 'save', 'fromServer', 'plain', 'singleOne');
    };
  });

}).call(this);

//# sourceMappingURL=sanitize-restangular-one.js.map
;(function() {
  'use strict';
  angular.module('store', ['store.core', 'store.localForage', 'store.rest', 'store.fileSystem']);


  /**
    * @ngdoc provider
    * @name Store
    * @description
    * # Store
    * Provider in the Store.
   */

  angular.module('store.core', []).provider('Store', function() {
    var configuration, createService;
    configuration = {
      adapterName: 'RESTAdapter'
    };
    createService = function($injector, $q, config) {
      var adapter, adapterClass, service;
      adapter = null;
      if (!$injector.has(config.adapterName)) {
        console.error('invalid_adapter');
      }
      adapterClass = $injector.get(config.adapterName);
      adapter = new adapterClass;
      service = {};
      service.withConfig = function(config) {
        var newConfig;
        newConfig = angular.copy(_.extend(configuration, config));
        return createService($injector, $q, newConfig);
      };
      service["new"] = function(type, record) {
        var deferred, model, modelName;
        deferred = $q.defer();
        modelName = _.str.classify(type) + 'Model';
        if ($injector.has(modelName)) {
          model = $injector.get(modelName);
          deferred.resolve(new model(record, type));
        } else {
          console.error('Invalid model', modelName);
          deferred.reject('invalid_model');
        }
        return deferred.promise;
      };
      service.getAdapter = function() {
        return adapter;
      };
      service.find = function(type, id) {
        if (typeof id === 'string' && !id.match(/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/)) {
          return this.findAll(type, id);
        }
        if (arguments.length === 1) {
          return this.findAll(type);
        }
        if (typeof id === 'object') {
          return this.findQuery(type, id);
        }
        id = parseInt(id, 10) || id;
        return this.findById(type, id);
      };
      service.findAll = function(type, subResourceName) {
        return adapter.findAll(type, subResourceName);
      };
      service.findQuery = function(type, query) {
        var deferred, model, modelName;
        deferred = $q.defer();
        modelName = _.str.classify(type) + 'Model';
        if ($injector.has(modelName)) {
          model = $injector.get(modelName);
          adapter.findQuery(type, query).then(function(records) {
            records = _.map(records, function(record) {
              return new model(record, type);
            });
            return deferred.resolve(records);
          });
        } else {
          console.error('Invalid model', modelName);
          deferred.reject('invalid_model');
        }
        return deferred.promise;
      };
      service.findByIds = function(type, ids) {
        var deferred, model, modelName;
        deferred = $q.defer();
        if (!ids) {
          console.error('ids parameter required');
        }
        modelName = _.str.classify(type) + 'Model';
        if ($injector.has(modelName)) {
          model = $injector.get(modelName);
          adapter.findByIds(type, ids).then(function(records) {
            return deferred.resolve(records);
          }, function(error) {
            return deferred.reject(error);
          });
        } else {
          console.error('Invalid model', modelName);
          deferred.reject('invalid_model');
        }
        return deferred.promise;
      };
      service.findBy = function(type, propertyName, value) {
        var deferred;
        deferred = $q.defer();
        adapter.findBy(type, propertyName, value).then(function(record) {
          var model, modelName;
          modelName = _.str.classify(type) + 'Model';
          if ($injector.has(modelName)) {
            model = $injector.get(modelName);
            record = new model(record, type);
            return deferred.resolve(record);
          } else {
            console.error('Invalid model', modelName);
            return deferred.reject('invalid_model');
          }
        }, function(error) {
          return deferred.reject(error);
        });
        return deferred.promise;
      };
      service.findById = function(type, id) {
        var deferred;
        if (!id) {
          console.error('id parameter required');
        }
        deferred = $q.defer();
        adapter.findById(type, id).then(function(record) {
          var model, modelName;
          modelName = _.str.classify(type) + 'Model';
          if ($injector.has(modelName)) {
            model = $injector.get(modelName);
            record = new model(record, type);
            return deferred.resolve(record);
          } else {
            console.error('Invalid model', modelName);
            return deferred.reject('invalid_model');
          }
        }, function(error) {
          return deferred.reject(error);
        });
        return deferred.promise;
      };
      service.createRecord = function(type, record) {
        return adapter.createRecord(type, record);
      };
      service.deleteRecord = function(type, record) {
        return adapter.deleteRecord(type, record);
      };
      service.saveRecord = function(record) {
        return adapter.saveRecord(record.type, record);
      };
      return service;
    };
    this.$get = function($injector, $q) {
      return createService($injector, $q, configuration);
    };
  });

}).call(this);

//# sourceMappingURL=store.js.map
