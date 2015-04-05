# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT REDACTOR
# -----------------------------------------------------------------------------
#
# Dependencies:
#= require redactor
#= require chr/vendor/redactor.fixedtoolbar
#
# -----------------------------------------------------------------------------

class @InputRedactor extends InputString

  # PRIVATE ===============================================

  _add_input: ->
    @$el.css('opacity', 0)
    @$input =$ "<textarea class='redactor' name='#{ @name }' rows=1>#{ @_safe_value() }</textarea>"
    @$el.append @$input


  # PUBLIC ================================================

  initialize: ->
    plugins = [ 'fixedtoolbar' ]
    if Loft? then plugins.push('loft')

    redactor_options =
      focus:            false
      imageFloatMargin: '20px'
      buttonSource:     true
      pastePlainText:   true
      plugins: plugins
      buttons: [ 'html', 'formatting', 'bold', 'italic', 'deleted', 'unorderedlist', 'orderedlist', 'link' ]

    @config.redactorOptions ?= {}
    $.extend(redactor_options, @config.redactorOptions)

    @$input.redactor(redactor_options)

    @$el.css('opacity', 1)

    @config.onInitialize?(this)


  updateValue: (@value) ->
    @$input.redactor('insert.set', @_safe_value())


chr.formInputs['redactor'] = InputRedactor




