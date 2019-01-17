
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')
moment   = require('moment')

require('bootstrap')

racers = require('./racers.js')

console.log racers

window.Templates = {}

$(document).ready () ->
    $('script[type="text/html-template"]').each () ->
        name = @id[2..]
        if Templates[name]
            console.log '[-] WARNING: conflicting template name:', name
        Templates[name] = _.template(@text)
        return

    new Derby

    return

class Derby
    constructor: () ->
        window.derby = @

        new racers.AddRacerModal

        @dispatch = _.clone(Backbone.Events)
        @dispatch.on 'connected', @OnConnected
        @socket = new Socket
            onmessage: (msg) =>
                #console.log 'WebSocket:', msg.action
                @dispatch.trigger(msg.action, msg)
                return

    # called after the websocket is successfully connected
    OnConnected: (msg) ->
        console.log 'Connected'
        new Router
        Backbone.history.start() if not Backbone.History.started
        return

    resizer: () ->
        w = $(document).width()
        h = $(document).height()
        return


Router = Backbone.Router.extend
    routes:
        '' : 'OnDefault'

    initialize: () ->
        return

    OnDefault: () ->
        return


@$SVG = (name) -> $ document.createElementNS('http://www.w3.org/2000/svg', name)

@cancelEvent = (e) ->
    e.preventDefault()
    e.stopPropagation()
    return false


class Socket
    constructor: (options) ->
        @options =
            timeout   : 0.9375
            maxtime   : 60
            ping      : 300
            onmessage : () ->

        @options[key] = value for key,value of options
        @timeout = @options.timeout
        @connect()
        return

    connect: () ->
        protocol = location.protocol.replace('http','ws')
        @ws = new WebSocket("#{protocol}//#{location.host}/ws")

        @ws.onopen = (event) =>
            @timeout = @options.timeout
            $('#ws-status').css('color', '#3c3')
            if @options.ping
                @interval = setInterval () =>
                    @ws.send('ping')
                    return
                  ,
                    1000 * @options.ping
            return

        @ws.onmessage = (event) =>
            msg = JSON.parse(event.data)
            @options.onmessage(msg)
            return

        @ws.onerror = (event) =>
            clearInterval(@interval)
            @timeout = @timeout * 2
            return

        @ws.onclose = (event) =>
            if event.code is 4004
                window.location.reload()
                return

            clearInterval(@interval)

            if @timeout > @options.maxtime
                $('#ws-status').css('color', '#c33')
                console.log('[!] Unable to reconnect to server, giving up.')
                return

            $('#ws-status').css('color', '#cc3')
            console.log('[-] Connection closed, reconnecting in', Math.round(@timeout))

            setTimeout () =>
                @connect()
                return
              ,
                1000 * @timeout
            return

        return
