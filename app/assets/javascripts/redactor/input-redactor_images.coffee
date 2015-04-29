# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# REDACTOR IMAGES
# -----------------------------------------------------------------------------

class @RedactorImages
  constructor: (@redactor) ->

    @redactor.opts.modal.imageEdit       = @_modal_edit_image()
    @redactor.image.update               = ($image) => @update($image)
    @redactor.image.showEdit             = ($image) => @_show_edit($image)
    @redactor.image.loadEditableControls = ($image) => @_load_editable_controls($image)


  _modal_edit_image: ->
    """<section id="redactor-modal-image-edit">
         <label>Image Alternative Text</label>
         <input type="text" id="redactor-image-title" />

         <label class="redactor-image-position-option">Position</label>
         <select class="redactor-image-position-option" id="redactor-image-align">
           <option value="none">None</option>
           <option value="left">Left</option>
           <option value="center">Center</option>
           <option value="right">Right</option>
         </select>

         <label class="redactor-image-link-option">Link URL</label>
         <input type="text" id="redactor-image-link-url" class="redactor-image-link-option" />

         <label class="redactor-image-link-option">Link Title</label>
         <input type="text" id="redactor-image-link-title" class="redactor-image-link-option" />

         <label class="redactor-image-link-option"><input type="checkbox" id="redactor-image-link-blank"> Open link in new tab</label>
       </section>"""


  update: ($image) ->
    @redactor.image.hideResize()
    @redactor.buffer.set()

    $link = $image.closest('a')

    $image.attr('alt', $('#redactor-image-title').val())

    @redactor.image.setFloating($image)

    # as link
    link  = $.trim($('#redactor-image-link-url').val())
    title = $.trim($('#redactor-image-link-title').val())

    if link != ''

      target = if ( $('#redactor-image-link-blank').prop('checked') ) then true else false

      if $link.size() == 0
        a =$ "<a href='#{ link }' title='#{ title }'>#{ @redactor.utils.getOuterHtml($image) }</a>"

        if target
          a.attr('target', '_blank')

        $image.replaceWith(a)

      else
        $link.attr('href', link)
        $link.attr('title', title)

        if target
          $link.attr('target', '_blank')

        else
          $link.removeAttr('target')

    else if $link.size() != 0
      $link.replaceWith(@redactor.utils.getOuterHtml($image))

    @redactor.modal.close()
    @redactor.observe.images()
    @redactor.code.sync()


  _show_edit: ($image) ->
    $link = $image.closest('a')

    @redactor.image.hideResize()
    @redactor.modal.load('imageEdit', @redactor.lang.get('edit'), 705)

    @redactor.modal.createCancelButton()
    @redactor.image.buttonDelete = @redactor.modal.createDeleteButton(@redactor.lang.get('_delete'))
    @redactor.image.buttonSave   = @redactor.modal.createActionButton(@redactor.lang.get('save'))

    @redactor.image.buttonDelete.on 'click', $.proxy(( => @redactor.image.remove($image) ), @redactor)
    @redactor.image.buttonSave.on   'click', $.proxy(( => @redactor.image.update($image) ), @redactor)

    $('#redactor-image-title').val($image.attr('alt'))

    if ! @redactor.opts.imageLink
      $('.redactor-image-link-option').hide()

    else
      $redactorImageLinkUrl   = $('#redactor-image-link-url')
      $redactorImageLinkTitle = $('#redactor-image-link-title')

      $redactorImageLinkUrl.attr('href', $image.attr('src'))

      if $link.size() != 0
        $redactorImageLinkUrl.val($link.attr('href'))
        $redactorImageLinkTitle.val($link.attr('title'))

        if $link.attr('target') == '_blank'
          $('#redactor-image-link-blank').prop('checked', true)

    if ! @redactor.opts.imagePosition
      $('.redactor-image-position-option').hide()

    else
      floatValue = if ($image.css('display') == 'block' && $image.css('float') == 'none') then 'center' else $image.css('float')
      $('#redactor-image-align').val(floatValue)

    @redactor.modal.show()


  # for some reason when image is a link, tooltip is shown with the image edit dialog,
  # add e.stopPropagation() to skip tooltip callback
  _load_editable_controls: ($image) ->
    imageBox =$ '<span id="redactor-image-box" data-redactor="verified">'
    imageBox.css('float', $image.css('float')).attr('contenteditable', false)

    if $image[0].style.margin != 'auto'
      imageBox.css
        marginTop:    $image[0].style.marginTop
        marginBottom: $image[0].style.marginBottom
        marginLeft:   $image[0].style.marginLeft
        marginRight:  $image[0].style.marginRight

      $image.css('margin', '')

    else
      imageBox.css({ 'display': 'block', 'margin': 'auto' })

    $image.css('opacity', '.5').after(imageBox)

    if @redactor.opts.imageEditable
      # editter
      @redactor.image.editter =$ "<span id='redactor-image-editter' data-redactor='verified'>Edit</span>"
      @redactor.image.editter.attr('contenteditable', false)
      @redactor.image.editter.on('click', $.proxy(( (e) => e.stopPropagation() ; @redactor.image.showEdit($image) ), @redactor))

      imageBox.append(@redactor.image.editter)

      # position correction
      editerWidth = @redactor.image.editter.innerWidth()
      @redactor.image.editter.css('margin-left', '-' + editerWidth/2 + 'px')

    return @redactor.image.loadResizableControls($image, imageBox)




