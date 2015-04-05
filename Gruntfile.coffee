module.exports = (grunt) ->
  # Project configuration
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    coffee:
      compileBare:
        options:
          bare: true
        files:
          'build/chr.js': [
            # core
            'app/assets/javascripts/chr/core/utils.coffee'
            'app/assets/javascripts/chr/core/chr.coffee'
            'app/assets/javascripts/chr/core/module.coffee'
            'app/assets/javascripts/chr/core/list_config.coffee'
            'app/assets/javascripts/chr/core/list_pagination.coffee'
            'app/assets/javascripts/chr/core/list_reorder.coffee'
            'app/assets/javascripts/chr/core/list_search.coffee'
            'app/assets/javascripts/chr/core/list.coffee'
            'app/assets/javascripts/chr/core/item.coffee'
            'app/assets/javascripts/chr/core/view.coffee'
            # form
            'app/assets/javascripts/chr/form/form.coffee'
            'app/assets/javascripts/chr/form/input-form_reorder.coffee'
            'app/assets/javascripts/chr/form/input-form.coffee'
            'app/assets/javascripts/chr/form/input-string.coffee'
            'app/assets/javascripts/chr/form/input-hidden.coffee'
            'app/assets/javascripts/chr/form/input-checkbox.coffee'
            'app/assets/javascripts/chr/form/input-color.coffee'
            'app/assets/javascripts/chr/form/input-date.coffee'
            'app/assets/javascripts/chr/form/input-file.coffee'
            'app/assets/javascripts/chr/form/input-list_reorder.coffee'
            'app/assets/javascripts/chr/form/input-list.coffee'
            'app/assets/javascripts/chr/form/input-password.coffee'
            'app/assets/javascripts/chr/form/input-select.coffee'
            'app/assets/javascripts/chr/form/input-text.coffee'
            # stores
            'app/assets/javascripts/chr/store/_array-store.coffee'
            'app/assets/javascripts/chr/store/_object-store.coffee'
            'app/assets/javascripts/chr/store/rest-array-store.coffee'
            'app/assets/javascripts/chr/store/rest-object-store.coffee'
            'app/assets/javascripts/chr/store/mongosteen-array-store.coffee'
            'app/assets/javascripts/chr/store/mongosteen-object-store.coffee'
          ]

          'build/input-ace.js': [
            'app/assets/javascripts/input-html.coffee'
            'app/assets/javascripts/input-markdown.coffee'
          ]

          'build/input-redactor.js': [
            'app/assets/javascripts/input-redactor.coffee'
          ]

    concat:
      chr:
        src: [
          'app/assets/javascripts/chr/vendor/slip.js'
          'app/assets/javascripts/chr/vendor/jquery.scrollparent.js'
          'app/assets/javascripts/chr/vendor/jquery.textarea_autosize.js'
          'app/assets/javascripts/chr/vendor/jquery.typeahead.js'
          'build/chr.js'
        ]
        dest: 'dist/chr.js'

      ace:
        src: [
          'app/assets/javascripts/chr/vendor/ace.js'
          'app/assets/javascripts/chr/vendor/mode-html.js'
          'app/assets/javascripts/chr/vendor/mode-markdown.js'
          'app/assets/javascripts/chr/vendor/marked.js'
          'build/input-ace.js'
        ]
        dest: 'dist/input-ace.js'

      redactor:
        src: [
          'app/assets/javascripts/chr/vendor/redactor.fixedtoolbar.js'
          'build/input-redactor.js'
        ]
        dest: 'dist/input-redactor.js'

    clean: [
      'build'
    ]

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-contrib-clean')

  grunt.registerTask('default', ['coffee', 'concat', 'clean'])




