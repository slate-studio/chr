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
class @InputDatetime extends InputDate

  # PRIVATE ===============================================

  # _update_date_label: ->
  #   time = @$input.val()
  #   date_formatted = moment(time).format("dddd, MMMM Do, YYYY") #, h:mm:ss a")
  #   @$dateLabel.html(date_formatted)


  _update_value: ->
    time = moment(@$inputTime.val(), 'LT').format()
    time = time.split('T')[1]
    date = @$inputDate.val()
    @$input.val([ date, time ].join('T'))


  _update_date_input: ->
    datetime = @$input.val()
    date = moment(datetime).format('YYYY-M-DD')
    if date == 'Invalid date'
      @$inputDate.val('')
    else
      @$inputDate.val(date)


  _update_date_label: ->
    date = @$inputDate.val()
    date_formatted = moment(date).format('dddd, MMM D, YYYY')
    if date_formatted == 'Invalid date'
      @$dateLabel.html('Pick a date')
    else
      @$dateLabel.html(date_formatted)


  _update_time_input: ->
    datetime = @$input.val()
    time = moment(datetime).format('h:mm a')
    if time == 'Invalid date'
      @$inputTime.val('')
    else
      @$inputTime.val(time)


  _add_input: ->
    # hidden
    @$input =$ "<input type='hidden' name='#{ @name }' value='#{ @_safe_value() }' />"
    @$el.append @$input

    # date
    @$inputDate =$ "<input type='text' class='input-datetime-date' />"
    @$el.append @$inputDate
    @$inputDate.on 'change', (e) =>
      @_update_date_label()
      @_update_value()

    # date label
    @$dateLabel =$ "<div class='input-date-label'>"
    @$el.append @$dateLabel
    @$dateLabel.on 'click', (e) => @$inputDate.trigger 'click'

    # @
    @$el.append "<span class='input-timedate-at'>@</span>"

    # time
    @$inputTime =$ "<input type='text' class='input-datetime-time' placeholder='12:00 am' />"
    @$el.append @$inputTime
    @$inputTime.on 'change', (e) => @_update_value()
    @$inputTime.on 'keyup',  (e) => @$input.trigger('change')

    @_update_date_input()
    @_update_date_label()
    @_update_time_input()


  # PUBLIC ================================================

  initialize: ->
    @config.beforeInitialize?(this)

    # http://felicegattuso.com/projects/datedropper/
    @config.pluginConfig ?= {}

    config =
      animation: 'fadein'
      format:    'Y-m-d'

    $.extend(config, @config.pluginConfig)

    @$inputDate.dateDropper(config)

    @config.onInitialize?(this)


  updateValue: (@value) ->
    @$input.val(@value)
    @_update_date_input()
    @_update_date_label()
    @_update_time_input()


chr.formInputs['datetime'] = InputDatetime




