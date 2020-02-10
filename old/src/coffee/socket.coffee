
$ = require('jquery')

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

module.exports = Socket
