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
            'app/assets/javascripts/chr/core/_item.coffee'
            'app/assets/javascripts/chr/core/_list.coffee'
            'app/assets/javascripts/chr/core/_listSearch.coffee'
            'app/assets/javascripts/chr/core/_listScroll.coffee'
            'app/assets/javascripts/chr/core/_listReorder.coffee'
            'app/assets/javascripts/chr/core/_view.coffee'
            'app/assets/javascripts/chr/core/_module.coffee'
            #
            'app/assets/javascripts/chr/form/_form.coffee'
            'app/assets/javascripts/chr/form/_inputString.coffee'
            'app/assets/javascripts/chr/form/_inputCheckbox.coffee'
            'app/assets/javascripts/chr/form/_inputColor.coffee'
            'app/assets/javascripts/chr/form/_inputFile.coffee'
            'app/assets/javascripts/chr/form/_inputHidden.coffee'
            'app/assets/javascripts/chr/form/_inputList.coffee'
            'app/assets/javascripts/chr/form/_inputSelect.coffee'
            'app/assets/javascripts/chr/form/_inputText.coffee'
            'app/assets/javascripts/chr/form/_nestedForm.coffee'
            #
            'app/assets/javascripts/chr/store/store.coffee'
            'app/assets/javascripts/chr/store/store-rest.coffee'
            'app/assets/javascripts/chr/store/store-mongosteen.coffee'
            #
            'app/assets/javascripts/chr/core/_utils.coffee'
            'app/assets/javascripts/chr/core/_chr.coffee'
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