# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# CHARACTER
# -----------------------------------------------------------------------------
# Public attributes:
#   modules
#   formInputs
#   itemsPerPageRequest
#
# Public methods:
#   start(@config)                 - start the character app with configuration
#   addMenuItem(moduleName, title) - add item to main menu
#   showAlert(message)             - show alert notification
#   showError(message)             - show error message
#   isMobile()                     - check if running on mobile
#   unsetActiveListItems()         - clear selection from all list items
#   updateHash(hash, skipHashChange=false)
#
# -----------------------------------------------------------------------------
class @Chr
  constructor: ->
    @formInputs = {}
    @modules    = {}

    @itemsPerPageRequest = Math.ceil($(window).height() / 60) * 2


  # PRIVATE ===============================================

  _unset_active_menu_items: ->
    $('.sidebar .menu a.active').removeClass('active')


  _set_active_menu_item: ->
    currentModuleName = window.location.hash.split('/')[1]
    for a in @$mainMenu.children()
      moduleName = $(a).attr('href').split('/')[1]
      if currentModuleName == moduleName
        return $(a).addClass('active')


  _navigate: (path) -> #/<module>[/<list>][/new]OR[/view/<objectId>]
    crumbs = path.split('/')

    # if module changed, hide previous module
    if @module != @modules[crumbs[1]]
      @module?.hide((path == '#/')) # NOTE: animate only for root path

    @module = @modules[crumbs[1]] # module name on position 1

    if @module
      @module.show()

      config = @module.config
      crumbs = crumbs.splice(2) # remove #/<module> part

      if crumbs.length > 0
        for crumb in crumbs
          if crumb == 'new'
            return @module.showView(null, config, 'New')

          if crumb == 'view'
            objectId = _last(crumbs)
            return @module.showViewByObjectId(objectId, config)

          config = config.items[crumb]

          if config.objectStore
            return @module.showViewByObjectId('', config, crumb.titleize())

          else
            @module.showNestedList(crumb)
      else
        @module.showRootList()


  # PUBLIC ================================================

  unsetActiveListItems: ->
    $('.list .items .item.active').removeClass('active')


  isMobile: ->
    $(window).width() < 760


  updateHash: (hash, skipHashChange=false) ->
    window._skipHashchange = skipHashChange
    location.hash = hash


  start: (@config) ->
    @$el       =$ (@config.selector ? 'body')
    @$navBar   =$ "<nav class='sidebar'>"
    @$mainMenu =$ "<div class='menu'>"

    @$navBar.append @$mainMenu
    @$el.append @$navBar

    @modules[name] = new Module(this, name, config) for name, config of @config.modules

    $(this).on 'hashchange', => @_set_active_menu_item()

    window.onhashchange = =>
      @_unset_active_menu_items()
      @unsetActiveListItems()

      # this allows to skip chr _navigate method for silent hashchanges,
      # e.g. close view event
      if not window._skipHashchange then @_navigate(location.hash)
      window._skipHashchange = false

      # triggers hashchange event which is used for navigation
      # related code, e.g. list active item selection
      $(this).trigger 'hashchange'

    # use class 'silent' for <a> when need to skip onhashchange event
    $(document).on 'click', 'a.silent', (e) -> window._skipHashchange = true

    # if not mobile navigate on first page load or page refresh
    window._skipHashchange = false

    # if hash is not empty go to module
    if location.hash != ''
      @_navigate(location.hash)
      $(this).trigger('hashchange')
    else if ! @isMobile()
      # if on desktop/tablet while hash is empty go to first module in the list
      location.hash = '#/' + Object.keys(@modules)[0]


  addMenuItem: (moduleName, title) ->
    @$mainMenu.append "<a href='#/#{ moduleName }'>#{ title }</a>"


  showAlert: (message) ->
    console.log 'Alert: ' + message


  showError: (message) ->
    alert 'Error: ' + message


# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
window.chr = new Chr()




