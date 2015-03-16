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
            #
            'app/assets/javascripts/chr/core/item.coffee'
            'app/assets/javascripts/chr/core/list.coffee'
            'app/assets/javascripts/chr/core/list-search.coffee'
            'app/assets/javascripts/chr/core/list-scroll.coffee'
            'app/assets/javascripts/chr/core/list-reorder.coffee'
            'app/assets/javascripts/chr/core/view.coffee'
            'app/assets/javascripts/chr/core/module.coffee'
            #
            'app/assets/javascripts/chr/form/form.coffee'
            'app/assets/javascripts/chr/form/input-string.coffee'
            'app/assets/javascripts/chr/form/input-checkbox.coffee'
            'app/assets/javascripts/chr/form/input-color.coffee'
            'app/assets/javascripts/chr/form/input-file.coffee'
            'app/assets/javascripts/chr/form/input-hidden.coffee'
            'app/assets/javascripts/chr/form/input-list.coffee'
            'app/assets/javascripts/chr/form/input-select.coffee'
            'app/assets/javascripts/chr/form/input-text.coffee'
            'app/assets/javascripts/chr/form/nested-form.coffee'
            #
            'app/assets/javascripts/chr/store/store.coffee'
            'app/assets/javascripts/chr/store/store-rest.coffee'
            'app/assets/javascripts/chr/store/store-mongosteen.coffee'
            #
            'app/assets/javascripts/chr/core/utils.coffee'
            'app/assets/javascripts/chr/core/chr.coffee'
          ]

    concat:
      vendor:
        src: [
          'app/assets/javascripts/chr/vendor/slip.js'
          'app/assets/javascripts/chr/vendor/jquery.scrollparent.js'
          'app/assets/javascripts/chr/vendor/jquery.textarea_autosize.js'
          'app/assets/javascripts/chr/vendor/jquery.typeahead.js'
          'build/chr.js'
        ]
        dest: 'app/assets/javascripts/chr-dist.js'

    clean: [
      'build'
    ]

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-contrib-clean')

  grunt.registerTask('default', ['coffee', 'concat', 'clean'])