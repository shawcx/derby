
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
        return

    OnAccept: () ->
        $.ajax
            method: 'POST'
            url: '/times/'
            data: JSON.stringify
                laneA:
                    racer: @selectA.racer_id
                    time:  @timeA
                laneB:
                    racer: @selectB.racer_id
                    time:   @timeB

            success: (data) =>
                if @selectA.racer_id != -1
                    racer = @collection.get @selectA.racer_id
                    count = racer.get('count')
                    count += 1
                    update = {}
                    update['time'+count] = @timeA.toFixed(4)
                    update['lane'+count] = 'A'
                    update['count'] = count
                    racer.set update
                    racer.calculateTotal()

                if @selectB.racer_id != -1
                    racer = @collection.get @selectB.racer_id
                    count = racer.get('count')
                    count += 1
                    update = {}
                    update['time'+count] = @timeB.toFixed(4)
                    update['lane'+count] = 'B'
                    update['count'] = count
                    racer.set update
                    racer.calculateTotal()
                    return

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
        @timeA = timeA
        @timeB = timeB
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
        @listenTo @collection, 'change', @RacerChange, @
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
            .append($("<option class=\"option-#{ racer.id }\" value=\"#{ racer.id }\">#{ racer.get('count') } - #{ racer.get('name') }</option>"))
        return

    RacerChange: (racer) ->
        count = racer.get('count')
        $option = $('.option-'+racer.id)
        if count < 4
            $option.text(count + ' - ' + racer.get('name'))
        else
            $option.remove()
            if @racer_id == racer.id
                @set(-1)
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
