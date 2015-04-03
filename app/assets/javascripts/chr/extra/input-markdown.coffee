# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT MARKDOWN
#
# Input configuration example:
#   body_md: { type: 'markdown', label: 'Article', htmlFieldName: 'body_html' }
#
# Dependencies:
#= require ../vendor/marked
#= require ../vendor/ace
#= require ../vendor/mode-markdown
# -----------------------------------------------------------------------------

class @InputMarkdown extends InputString
  _addInput: ->
    @$inputHtml =$ "<input type='hidden' name='[#{ @config.htmlFieldName }]' />"
    @$el.append @$inputHtml

    @$input =$ "<input type='hidden' name='#{ @name }' value='#{ @_valueSafe() }' />"
    @$el.append @$input

    @$editor =$ "<div></div>"
    @$el.append @$editor


  _update_value: ->
    md_source = @editor.getSession().getValue()
    html      = marked(md_source)

    @$input.val(md_source)
    @$inputHtml.val(html)


  initialize: ->
    @editor = ace.edit(@$editor.get(0))

    # options: https://github.com/ajaxorg/ace/wiki/Configuring-Ace
    @editor.setOptions
      autoScrollEditorIntoView: true
      minLines:                 5
      maxLines:                 Infinity
      showLineNumbers:          false
      showGutter:               false
      highlightActiveLine:      false

    # disable warning
    @editor.$blockScrolling = Infinity

    @editor.getSession().setValue(@$input.val())
    @editor.getSession().setMode("ace/mode/markdown")

    @editor.getSession().on 'change', (e) => @_update_value()

    @config.onInitialize?(this)


  updateValue: (@value) ->
    @editor.getSession().setValue(@value)
    @_update_value()


_chrFormInputs['markdown'] = InputMarkdown




