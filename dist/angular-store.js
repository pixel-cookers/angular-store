(function() {
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

  angular.module('store.fileSystem.core', ['store.fileSystem.restangular']).factory('FileSystemAdapter', function($q, FileSystemAdapterRestangular) {
    var FileSystemAdapter, createRecord, deleteRecord, findAll, findBy, findById, findQuery;
    findAll = function(type) {
      return FileSystemAdapterRestangular.all(pluralize(type)).getList();
    };
    findQuery = function(type, query) {
      var deferred;
      deferred = $q.defer();
      FileSystemAdapterRestangular.all(pluralize(type)).getList().then(function(records) {
        records = _.filter(records, query);
        if (records) {
          return deferred.resolve(records);
        } else {
          return deferred.reject('not_found');
        }
      });
      return deferred.promise;
    };
    findById = function(type, id) {
      var deferred;
      deferred = $q.defer();
      FileSystemAdapterRestangular.all(pluralize(type)).getList().then(function(records) {
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
    findBy = function(type, propertyName, value) {
      var deferred;
      deferred = $q.defer();
      FileSystemAdapterRestangular.all(pluralize(type)).getList().then(function(records) {
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
      });
      return deferred.promise;
    };
    createRecord = function(type, record) {
      return console.log('createRecord', type, record);
    };
    deleteRecord = function(type, record) {
      return console.log('deleteRecord', type, record);
    };
    return FileSystemAdapter = (function() {
      function FileSystemAdapter() {}

      FileSystemAdapter.prototype.findAll = function(type) {
        return findAll(type);
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

  angular.module('store.rest.core', ['store.rest.restangular']).factory('sanitizeRestangularOne', function() {
    return function(item) {
      return _.omit(item, 'route', 'parentResource', 'getList', 'get', 'post', 'put', 'remove', 'head', 'trace', 'options', 'patch', '$then', '$resolved', 'restangularCollection', 'customOperation', 'customGET', 'customPOST', 'customPUT', 'customDELETE', 'customGETLIST', '$getList', '$resolved', 'restangularCollection', 'one', 'all', 'doGET', 'doPOST', 'doPUT', 'doDELETE', 'doGETLIST', 'addRestangularMethod', 'getRestangularUrl', 'several', 'getRequestedUrl', 'clone', 'reqParams', 'withHttpConfig', 'oneUrl', 'allUrl', 'getParentList', 'save', 'fromServer', 'plain', 'singleOne');
    };
  }).factory('RESTAdapter', function(RESTAdapterRestangular, sanitizeRestangularOne, $q) {
    var LocalForageAdapter, createRecord, deleteRecord, findAll, findById, findQuery;
    findAll = function(type) {
      return RESTAdapterRestangular.all(pluralize(type)).getList();
    };
    findQuery = function(type, query) {
      return RESTAdapterRestangular.all(pluralize(type)).getList(query);
    };
    findById = function(type, id) {
      var deferred;
      deferred = $q.defer();
      RESTAdapterRestangular.one(pluralize(type), id).get().then(function(record) {
        var pluralizedPropertyName, propertyName;
        for (propertyName in sanitizeRestangularOne(record)) {
          if (_.include(propertyName, '_ids')) {
            if (record.originalResponse) {
              pluralizedPropertyName = pluralize(propertyName.replace('_ids', ''));
              if (record.originalResponse[pluralizedPropertyName]) {
                record[pluralizedPropertyName] = record.originalResponse[pluralizedPropertyName];
              }
            }
          }
        }
        return deferred.resolve(record);
      });
      return deferred.promise;
    };
    createRecord = function(type, record) {
      return console.log('createRecord', type, record);
    };
    deleteRecord = function(type, record) {
      return console.log('deleteRecord', type, record);
    };
    return LocalForageAdapter = (function() {
      function LocalForageAdapter() {}

      LocalForageAdapter.prototype.findAll = function(type) {
        return findAll(type);
      };

      LocalForageAdapter.prototype.findByIds = function(type, ids) {
        return findByIds(type, ids);
      };

      LocalForageAdapter.prototype.findById = function(type, id) {
        return findById(type, id);
      };

      LocalForageAdapter.prototype.createRecord = function(type, record) {
        return createRecord(type, record);
      };

      LocalForageAdapter.prototype.deleteRecord = function(type, record) {
        return deleteRecord(type, record);
      };

      return LocalForageAdapter;

    })();
  });

}).call(this);

//# sourceMappingURL=rest-adapter.js.map
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
    var adapter, adapterName;
    adapter = null;
    adapterName = null;
    this.$get = function($injector, $q) {
      return {
        "new": function(type) {
          var deferred, model;
          model = $injector.get(_.str.classify(type) + 'Model');
          deferred = $q.defer();
          deferred.resolve(new model());
          return deferred.promise;
        },
        find: function(type, id) {
          var adapterClass;
          adapterClass = $injector.get(_.str.classify(type) + 'Adapter');
          adapter = new adapterClass;
          if (arguments.length === 1) {
            return this.findAll(type);
          }
          if (typeof id === 'object') {
            return this.findQuery(type, id);
          }
          id = parseInt(id, 10) || id;
          return this.findById(type, id);
        },
        findAll: function(type) {
          var deferred, model;
          model = $injector.get(_.str.classify(type) + 'Model');
          deferred = $q.defer();
          adapter.findAll(type).then(function(records) {
            records = _.map(records, function(record) {
              return new model(record);
            });
            return deferred.resolve(records);
          });
          return deferred.promise;
        },
        findQuery: function(type, query) {
          var deferred, model;
          model = $injector.get(_.str.classify(type) + 'Model');
          deferred = $q.defer();
          adapter.findQuery(type, query).then(function(records) {
            records = _.map(records, function(record) {
              return new model(record);
            });
            return deferred.resolve(records);
          });
          return deferred.promise;
        },
        findByIds: function(type, ids) {
          var adapterClass, deferred, model;
          model = $injector.get(_.str.classify(type) + 'Model');
          adapterClass = $injector.get(_.str.classify(type) + 'Adapter');
          adapter = new adapterClass;
          deferred = $q.defer();
          adapter.findByIds(type, ids).then(function(records) {
            records = _.map(records, function(record) {
              return new model(record);
            });
            return deferred.resolve(records);
          });
          return deferred.promise;
        },
        findBy: function(type, propertyName, value) {
          var adapterClass, deferred;
          adapterClass = $injector.get(_.str.classify(type) + 'Adapter');
          adapter = new adapterClass;
          deferred = $q.defer();
          adapter.findBy(type, propertyName, value).then(function(record) {
            var model;
            model = $injector.get(_.str.classify(type) + 'Model');
            record = new model(record);
            return deferred.resolve(record);
          });
          return deferred.promise;
        },
        findById: function(type, id) {
          var adapterClass, deferred;
          adapterClass = $injector.get(_.str.classify(type) + 'Adapter');
          adapter = new adapterClass;
          deferred = $q.defer();
          adapter.findById(type, id).then(function(record) {
            var model;
            model = $injector.get(_.str.classify(type) + 'Model');
            record = new model(record);
            return deferred.resolve(record);
          });
          return deferred.promise;
        },
        createRecord: function(type, record) {
          var adapterClass;
          adapterClass = $injector.get(_.str.classify(type) + 'Adapter');
          adapter = new adapterClass;
          return adapter.createRecord(type, record);
        },
        deleteRecord: function(type, record) {
          var adapterClass;
          adapterClass = $injector.get(_.str.classify(type) + 'Adapter');
          adapter = new adapterClass;
          return adapter.deleteRecord(type, record);
        },
        saveRecord: function(record) {
          var adapterClass, className, type;
          className = record.constructor.name;
          className = className.replace('Model', '');
          type = _.str.underscored(className);
          adapterClass = $injector.get("" + className + "Adapter");
          adapter = new adapterClass;
          return adapter.saveRecord(type, record);
        }
      };
    };
  });

}).call(this);

//# sourceMappingURL=store.js.map
