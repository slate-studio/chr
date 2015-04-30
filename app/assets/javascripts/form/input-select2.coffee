# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT SELECT 2
# -----------------------------------------------------------------------------
#
# Dependencies:
#= require vendor/select2
#
# -----------------------------------------------------------------------------

class @InputSelect2 extends InputSelect
  initialize: ->
    @config.beforeInitialize?(this)

    # https://select2.github.io/options.html
    options = @config.pluginOptions || {}
    @$input.select2(options)

    @config.onInitialize?(this)


chr.formInputs['select2'] = InputSelect2




