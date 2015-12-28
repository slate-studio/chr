#= require test_helper

suite 'Icons', ->
  test '.reorder', ->
    assert.equal "<i class='fa fa-ellipsis-v'></i>", Icons.reorder()