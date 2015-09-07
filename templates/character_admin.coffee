#= require jquery
#= require jquery_ujs

#= require chr
#= require loft
#= require ants

@settingsConfig = ->
  items:
    admins:    Ants.adminsConfig()
    redirects: Ants.redirectsConfig()

@getChrConfig = (data) ->
  modules     = {}
  all_modules =
    settings:  settingsConfig()

  return { modules: all_modules }

$ ->
  $.get '/admin/bootstrap.json', (response) ->
    chrConfig = getChrConfig(response)

    chr.start(chrConfig)

    # append signout button to the end of sidebar menu
    $('a[data-method=delete]').appendTo(".sidebar .menu").show()