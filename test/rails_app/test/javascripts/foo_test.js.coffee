#= require test_helper

suite 'Foo', ->
  setup ->
    @server = sinon.fakeServer.create()
    @foo = new Foo()

  teardown ->
    @server.restore()
    return


  test '#bar', ->
    assert.equal 'bar', @foo.bar()

  test 'template', ->
    $('body').html(JST['templates/hello']())
    @foo.change_h1()
    assert.equal 'Title Changed', $('body h1').text(), 'There are no h1 with this title'
    assert $('body h1').length == 1, 'We don`t have one h1'

  test 'async', ->
    spy = sinon.spy()
    @foo.request(spy)
    fake_response = ->
      @server.requests[0].respond(200,{},'')
    # assert "spy was called once"

