# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# INPUT MARKDOWN
# -----------------------------------------------------------------------------
# Markdown input supports syntax highlighting and optional compilation to html.
#
# Config options:
#   label         - Input label
#   aceOptions    - Custom options for overriding default ones
#   htmlFieldName - Input name for generated HTML content
#
# Input config example:
#   body_md: { type: 'markdown', label: 'Article', htmlFieldName: 'body_html' }
#
# Dependencies:
#= require chr/vendor/marked
#= require chr/vendor/ace
#= require chr/vendor/mode-markdown
#
# -----------------------------------------------------------------------------

class @InputMarkdown extends InputString

  # PRIVATE ===============================================

  _add_input: ->
    if @config.htmlFieldName
      @$inputHtml =$ "<input type='hidden' name='[#{ @config.htmlFieldName }]' />"
      @$el.append @$inputHtml

    @$input =$ "<input type='hidden' name='#{ @name }' value='#{ @_safe_value() }' />"
    @$el.append @$input

    @$editor =$ "<div></div>"
    @$el.append @$editor


  _update_inputs: ->
    md_source = @session.getValue()
    @$input.val(md_source)
    @$input.trigger('change')

    if @$inputHtml
      html = marked(md_source)
      @$inputHtml.val(html)
      @$inputHtml.trigger('change')


  # PUBLIC ================================================

  initialize: ->
    @editor = ace.edit(@$editor.get(0))
    @editor.$blockScrolling = Infinity

    @session = @editor.getSession()
    @session.setValue(@$input.val())
    @session.setUseWrapMode(true)
    @session.setMode("ace/mode/markdown")

    # options: https://github.com/ajaxorg/ace/wiki/Configuring-Ace
    @editor.setOptions
      autoScrollEditorIntoView: true
      minLines:                 5
      maxLines:                 Infinity
      showLineNumbers:          false
      showGutter:               false
      highlightActiveLine:      false
      showPrintMargin:          false

    @session.on 'change', (e) => @_update_inputs()

    @config.onInitialize?(this)


  updateValue: (@value) ->
    @session.setValue(@value)
    @_update_inputs()


chr.formInputs['markdown'] = InputMarkdown




