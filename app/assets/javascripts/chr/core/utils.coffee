# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# UTILS
# -----------------------------------------------------------------------------
# Public methods:
#   _any(array)
#   _last(array)
#   _first(array)
#   _firstNonEmptyValue(hash)
#   _escapeHtml(string)
#   String.titleize()
#   String.reverse()
#   String.startsWith(str)
#   String.endsWith(str)
#   String.plainText()
#   include(class, hash)
# -----------------------------------------------------------------------------

# _any(array)
@_any = (array) -> array.length > 0

# _last(array)
@_last = (array) -> array[array.length - 1]

# _first(array)
@_first = (array) -> array[0]

# _firstNonEmptyValue(hash)
@_firstNonEmptyValue = (o) -> ((return v if k[0] != '_' and v and v != '') for k, v of o) ; return null

# _escapeHtml(string)
@_entityMap  = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': '&quot;', "'": '&#39;', "/": '&#x2F;' }
@_escapeHtml = (string) -> String(string).replace /[&<>"'\/]/g, (s) -> _entityMap[s]

# String.titleize
if typeof String.prototype.titleize != 'function'
  String.prototype.titleize = -> return this.replace(/_/g, ' ').replace(/\b./g, ((m) -> m.toUpperCase()))

# String.reverse
if typeof String.prototype.reverse != 'function'
  String.prototype.reverse = -> return this.split("").reverse().join("")

# String.startsWith
if typeof String.prototype.startsWith != 'function'
  String.prototype.startsWith = (str) -> return this.slice(0, str.length) == str

# String.endsWith
if typeof String.prototype.endsWith != 'function'
  String.prototype.endsWith = (str) -> return this.slice(this.length - str.length, this.length) == str

# String.plainText
if typeof String.prototype.plainText != 'function'
  String.prototype.plainText = () -> return $("<div>#{ this }</div>").text()


# -----------------------------------------------------------------------------
# Mixins: http://arcturo.github.io/library/coffeescript/03_classes.html
# -----------------------------------------------------------------------------
@extend = (obj, mixin) ->
  obj[name] = method for name, method of mixin
  return obj

@include = (klass, mixin) ->
  extend(klass.prototype, mixin)




