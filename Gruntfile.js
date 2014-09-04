'use strict';

module.exports = function (grunt) {

	// Load grunt tasks automatically
	require('load-grunt-tasks')(grunt);

	// Time how long tasks take. Can help when optimizing build times
	require('time-grunt')(grunt);

	// Define the configuration for all the tasks
	grunt.initConfig({

		// Watches files for changes and runs tasks based on the changed files
		watch: {
			coffee: {
				files: ['src/*.coffee'],
				tasks: ['coffee:dist']
			},
			concat: {
				files: ['.tmp/*.js'],
				tasks: ['concat']
			}
		},

		// Compiles CoffeeScript to JavaScript
		coffee: {
			options: {
				sourceMap: true,
				sourceRoot: ''
			},
			dist: {
				files: [{
					expand: true,
					cwd: 'src',
					src: '*.coffee',
					dest: '.tmp',
					ext: '.js'
				}]
			}
		},

		// ngmin tries to make the code safe for minification automatically by
		// using the Angular long form for dependency injection. It doesn't work on
		// things like resolve or inject so those have to be done manually.
		ngmin: {
			dist: {
				files: [{
					expand: true,
					cwd: '.tmp/concat',
					src: '*.js',
					dest: '.tmp/concat'
				}]
			}
		},

    // Empties folders to start fresh
    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '.tmp',
            'dist/*',
            '!dist/.git*'
          ]
        }]
      },
      server: '.tmp'
    },

		// Run some tasks in parallel to speed up the build process
		concurrent: {
			server: [
				'coffee:dist'
			],
			dist: [
				'coffee'
			]
		},

		concat: {
	    options: {
	      separator: ';',
	    },
	    server: {
	      src: ['.tmp/*.js'],
	      dest: 'dist/angular-store.js',
	    },
	  },

	  uglify: {
	    dist: {
	      files: {
	        'dist/angular-store.min.js': ['dist/angular-store.js']
	      }
	    }
	  }

	});

	grunt.registerTask('serve', 'Compile then start a connect web server', function () {
		grunt.task.run([
			'concurrent:server',
			'concat',
			'watch'
		]);
	});

	grunt.registerTask('build', [
		'clean:dist',
		'concurrent:dist',
		'concat',
		'ngmin',
		'uglify:dist'
	]);

	grunt.registerTask('default', [
		'build'
	]);
};
