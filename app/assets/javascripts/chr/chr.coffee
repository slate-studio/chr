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
#
# Public attributes:
#   modules
#   formInputs
#   itemsPerPageRequest
#
# Public methods:
#   start(@config)              - start the character app with configuration
#   updateHash(hash, skipRoute) - change window location hash
#   isMobile()                  - check if running on mobile
#   showAlert(message)          - show alert notification
#   showError(message)          - show error message
#
# Dependencies:
#= require ./chr_router
#
# -----------------------------------------------------------------------------
class @Chr
  constructor: ->
    @formInputs = {}
    @modules    = {}

    @itemsPerPageRequest = Math.ceil($(window).height() / 60) * 2


  # PRIVATE ===============================================

  _unset_active_items: ->
    $('.sidebar .menu a.active').removeClass('active')
    $('.list .items .item.active').removeClass('active')


  _set_active_menu_item: ->
    currentModuleName = window.location.hash.split('/')[1]
    for a in @$mainMenu.children()
      moduleName = $(a).attr('href').split('/')[1]
      if currentModuleName == moduleName
        return $(a).addClass('active')


  _add_menu_item: (moduleName, title, icon) ->
    if icon
      @$mainMenu.append("""<a href="#/#{ moduleName }" class="menu-#{ moduleName }">
        <i class="fa fa-#{icon} fa-fw"></i>&nbsp;#{ title }</a>""")
    else
      @$mainMenu.append "<a href='#/#{ moduleName }' class='menu-#{ moduleName }'>#{ title }</a>"


  _bind_hashchange: ->
    @skipRoute = false

    window.onhashchange = =>
      @_unset_active_items()

      if ! @skipRoute then @_route()
      @skipRoute = false

      $(this).trigger 'hashchange'

    $(this).on 'hashchange', => @_set_active_menu_item()


  _on_start: ->
    if location.hash != ''
      @_route()
      return $(this).trigger('hashchange')

    if ! @isMobile()
      firstMenuItemPath = @$mainMenu.find(".menu-#{ Object.keys(@modules)[0] }").attr('href')
      return @updateHash(firstMenuItemPath)


  # PUBLIC ================================================

  isMobile: ->
    $(window).width() < 768


  isTablet: ->
    ! @isMobile() && ! @isDesktop()


  isDesktop: ->
    $(window).width() >= 1024


  updateHash: (path, @skipRoute=false) ->
    window.location.hash = path


  start: (title, @config) ->
    @$el        =$ (@config.selector ? 'body')
    @$navBar    =$ "<nav class='sidebar'>"
    @$mainMenu  =$ "<div class='menu'>"
    @$navBar.append(@$mainMenu)
    @$el.append(@$navBar)

    for name, config of @config.modules
      m = new Module(this, name, config)
      @_add_menu_item(name, m.menuTitle, m.menuIcon)
      m.onModuleInit()
      @modules[name] = m

    @_bind_hashchange()
    @_on_start()


  showAlert: (message) ->
    console.log 'Alert: ' + message


  showError: (message) ->
    alert 'Error: ' + message

  showNotification: (message) ->
    alert message


include(Chr, chrRouter)


# ---------------------------------------------------------
# Initialize `chr` object in global scope
# ---------------------------------------------------------
window.chr = new Chr()




