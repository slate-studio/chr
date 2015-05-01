# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# REDACTOR CUSTOM VERSION
#= require ./input-redactor_images
# -----------------------------------------------------------------------------

# change default fast speed from 200 to 10 as it's used by redactor modals
# while closing
console.log ':: [redactor-character] change $.fx.speeds.fast from 200 to 10 ::'
$.fx.speeds.fast = 10

@redactorCharacter =

  # PRIVATE ===============================================

  # TODO: fixed toolbar disabled on mobile
  _redactor_options: ->
    @_trigger_change = true

    config = @_get_default_config()
    @config.redactorOptions ?= {}

    $.extend(config, @config.redactorOptions)

    if (! chr.isMobile()) && config.plugins.indexOf('fixedtoolbar') == -1
      config.plugins.push('fixedtoolbar')

    if Loft? && config.plugins.indexOf('loft') == -1
      config.plugins.push('loft')

    if chr.isMobile()
      config.toolbarFixed = false
      # config.toolbarFixedTopOffset = 40

    return config


  _get_default_config: () ->
    focus:            false
    imageFloatMargin: '20px'
    buttonSource:     true
    pastePlainText:   true
    scrollTarget:     chr.module.view.$content
    plugins:          []
    buttons:          [ 'html',
                        'formatting',
                        'bold',
                        'italic',
                        'deleted',
                        'unorderedlist',
                        'orderedlist',
                        'link' ]

    # to have caching working we need to trigger 'change' event for textarea
    # when content got changed in redactor, but skip this when updating value
    # via `updateValue` method
    changeCallback: =>
      if @_trigger_change
        @$input.trigger('change')
      @_trigger_change = true

    initCallback: ->
      new RedactorImages(this)





