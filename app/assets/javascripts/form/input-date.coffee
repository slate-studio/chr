# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT DATE
# -----------------------------------------------------------------------------
#
# Dependencies:
#= require vendor/datedropper
#= require vendor/moment
#
# -----------------------------------------------------------------------------
class @InputDate extends InputString

  # PRIVATE ===============================================

  _update_date_label: ->
    date = @$input.val()
    date_formatted = moment(date).format("dddd, MMMM Do, YYYY")
    @$dateLabel.html(date_formatted)


  _add_input: ->
    @$input =$ "<input type='text' name='#{ @name }' value='#{ @_safe_value() }' class='input-datetime-date' />"
    @$el.append @$input
    @$input.on 'change', (e) => @_update_date_label()

    @$dateLabel =$ "<div class='input-date-label'>"
    @$el.append @$dateLabel
    @$dateLabel.on 'click', (e) => @$input.trigger 'click'

    @_update_date_label()


  # PUBLIC ================================================

  initialize: ->
    @config.beforeInitialize?(this)

    # http://felicegattuso.com/projects/datedropper/
    @config.pluginConfig ?= {}

    config =
      animation: 'fadein'
      format:    'Y-m-d'

    $.extend(config, @config.pluginConfig)

    @$input.dateDropper(config)

    @config.onInitialize?(this)


  updateValue: (@value) ->
    @$input.val(@value)
    # @TODO: check if required, cause change event might be triggered
    #@_update_date_label()


chr.formInputs['date'] = InputDate




