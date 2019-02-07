
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class HeatModal extends Backbone.View
    el: () -> $('#heat-modal')

    events:
        'click #gateRelease' : 'OnRelease'
        'click #acceptTimes' : 'OnAccept'
        'click #resetTimes'  : 'OnReset'
        'click #swapLanes'   : 'OnSwapLanes'

    initialize: (options) ->
        @needAccept = false
        @ready = false
        @render()
        return @

    render: () ->
        @selectA = new RaceSelect
            collection: @collection
            parent: @
            lane: 'A'

        @selectB = new RaceSelect
            collection: @collection
            parent: @
            lane: 'B'

        @$('#heat-container-a').append(@selectA.$el)
        @$('#heat-container-b').append(@selectB.$el)
        return @

    OnRelease: () ->
        return if not @ready

        lightUp = (element, className) =>
            $(element).addClass(className)
            return

        delay = 750
        $.ajax
            method: 'GET'
            url: '/serial'
            success: (data) ->
                _.delay(lightUp, delay * 0, '#lightyellow1', 'bright-yellow')
                _.delay(lightUp, delay * 1, '#lightyellow2', 'bright-yellow')
                _.delay(lightUp, delay * 2, '#lightyellow3', 'bright-yellow')
                _.delay(lightUp, delay * 3, '#lightgreen',   'bright-green')
        return

    OnAccept: () ->
        $('#lightyellow1').removeClass('bright-yellow')
        $('#lightyellow2').removeClass('bright-yellow')
        $('#lightyellow3').removeClass('bright-yellow')
        $('#lightgreen').removeClass('bright-green')
        @reset()
        return

    OnSwapLanes: () ->
        newB = @selectA.racer_id
        newA = @selectB.racer_id
        @selectA.set(newA)
        @selectB.set(newB)
        return

    OnReset: () ->
        return if not confirm('Really reset times?')
        @reset()
        return

    reset: () ->
        $('#acceptTimes').prop('disabled', true)
        @$('.board').removeClass('board-winner')

        @selectA.$el.find('.avatar').removeClass('spinner')
        @selectB.$el.find('.avatar').removeClass('spinner')

        @selectA.$('.time').text '-.----'
        @selectB.$('.time').text '-.----'
        @needAccept = false
        @checkGateReady()
        return

    gate: (gateClosed) ->
        @gateClosed = gateClosed
        @checkGateReady()
        return

    checkGateReady: () ->
        if not @gateClosed
            @$('#gateRelease').removeClass('bright-red')
            @ready = false
            return false

        if @selectA.racer_id == @selectB.racer_id
            @$('#gateRelease').removeClass('bright-red')
            @ready = false
            return false

        if @needAccept
            return false

        @$('#gateRelease').addClass('bright-red')
        @ready = true
        return true

    results: (timeA, timeB) ->
        @selectA.result(timeA)
        @selectB.result(timeB)


        if timeA == 0 and timeB == 0
            console.log 'both lose'
        else if timeA == 0
            $('#board-B').addClass('board-winner')
            @selectB.$el.find('.avatar').addClass('spinner')
        else if timeB == 0
            $('#board-A').addClass('board-winner')
            @selectA.$el.find('.avatar').addClass('spinner')
        else
            if timeA < timeB
                $('#board-A').addClass('board-winner')
                @selectA.$el.find('.avatar').addClass('spinner')
            else if timeA > timeB
                $('#board-B').addClass('board-winner')
                @selectB.$el.find('.avatar').addClass('spinner')
            else if timeA == timeB
                $('#board-A').addClass('board-winner')
                $('#board-B').addClass('board-winner')
                @selectA.$el.find('.avatar').addClass('spinner')
                @selectB.$el.find('.avatar').addClass('spinner')
            else
                console.error 'unreachable state', timeA, timeB
                return

        @needAccept = true
        $('#acceptTimes').prop('disabled', false)
        return

module.exports.HeatModal = HeatModal


class RaceSelect extends Backbone.View
    events:
        'change' : 'OnChange'

    initialize: (options) ->
        @racer_id = -1
        @parent   = options.parent
        @lane     = options.lane

        @render()

        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        return @

    render: () ->
        values =
            lane: @lane
        @$el.html Templates['heat-select'] values
        @$select = @$('select')
        return @

    Add: (racer) ->
        den = racer.get('den').toLocaleLowerCase()
        @$select
            .find('.den-'+den)
            .append($("<option value=\"#{ racer.id }\">#{ racer.get('name') }</option>"))
        return

    OnChange: () ->
        @set(parseInt(@$select.val()))
        return

    set: (@racer_id) ->
        if @racer_id == -1
            src = '/static/images/empty.png'
        else
            racer = @collection.get(@racer_id)
            src = racer.get('avatar')
        @$select.val(@racer_id)
        @$('img.avatar').attr('src', src)
        @parent.checkGateReady()
        return

    result: (time) ->
        if time != 0
        then @$('.time').text time.toFixed(4)
        else @$('.time').text '😞'
        return
