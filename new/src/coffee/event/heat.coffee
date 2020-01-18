
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
        @racers = options.racers
        @groups = options.groups

        @needAccept = false
        @ready = false
        @render()
        return @

    render: () ->
        @selectA = new RaceSelect
            racers: @racers
            groups: @groups
            parent: @
            lane: 'A'

        @selectB = new RaceSelect
            racers: @racers
            groups: @groups
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
            method: 'POST'
            url: '/serial'
            data:
                action: 'release'
                racerA: @selectA.racer_id
                racerB: @selectB.racer_id
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
                    racer = @racers.get @selectA.racer_id
                    count = racer.get('count')
                    count += 1
                    update = {}
                    update['time'+count] = @timeA.toFixed(4)
                    update['lane'+count] = 'A'
                    update['count'] = count
                    racer.set update
                    racer.calculateTotal()
                if @selectB.racer_id != -1
                    racer = @racers.get @selectB.racer_id
                    count = racer.get('count')
                    count += 1
                    update = {}
                    update['time'+count] = @timeB.toFixed(4)
                    update['lane'+count] = 'B'
                    update['count'] = count
                    racer.set update
                    racer.calculateTotal()
                @racers.sort()
                @OnSwapLanes()
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

        @$('.board').removeClass('board-winner')

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

        _.delay () =>
            @selectA.$el.find('.avatar').removeClass('spinner')
            @selectB.$el.find('.avatar').removeClass('spinner')
            return
          ,
            1500

        @needAccept = true
        $('#acceptTimes').prop('disabled', false)
        return

module.exports.HeatModal = HeatModal


class RaceSelect extends Backbone.View
    events:
        'change' : 'OnChange'

    initialize: (options) ->
        @racer_id = -1
        @racers   = options.racers
        @groups   = options.groups
        @parent   = options.parent
        @lane     = options.lane

        @render()

        @listenTo @racers, 'add', @Add, @
        @listenTo @racers, 'change', @RacerChange, @
        @listenTo @racers, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        @listenTo @racers, 'remove', (racer) =>
            $option = $('.option-'+racer.id)
            $option.remove()
            return

        @listenTo @groups, 'add', @AddGroup, @
        @listenTo @groups, 'reset', (groups) =>
            groups.forEach @AddGroup, @
            return
        return @

    AddGroup: (group) ->
        console.log 'add group...', group.get('group')
        btn = new GroupSelect
            model: group
        @$('select').append(btn.$el)
        return

    render: () ->
        values =
            lane: @lane

        if @racer_id == -1
            values.time1 = values.time2 = values.time3 = values.time4 = '----.-'
            values.lane1 = values.lane2 = values.lane3 = values.lane4 = '-'

        @$el.html Templates['heat-select'] values
        @$select = @$('select')
        return @

    Add: (racer) ->
        group = @groups.get(racer.get('group_id')).get('group')
        #group = group.toLocaleLowerCase()
        #console.log 'TODO: add racer in heat.coffee', racer.get('group_id'), group
        @$select
            .find('.group-'+group)
            .append($("<option class=\"option-#{ racer.id }\" value=\"#{ racer.id }\">#{ racer.get('count') } - #{ racer.get('racer') }</option>"))
        return

    RacerChange: (racer) ->
        count = racer.get('count')
        $option = $('.option-'+racer.id)
        if count < 4
            $option.text(count + ' - ' + racer.get('racer'))
            if @racer_id == racer.id
                @updateTimes(racer.toJSON())
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
            values = {}
            values.time1 = values.time2 = values.time3 = values.time4 = '----.-'
            values.lane1 = values.lane2 = values.lane3 = values.lane4 = '-'
            @updateTimes(values)
        else
            racer = @racers.get(@racer_id)
            src = racer.get('avatar')
            @updateTimes(racer.toJSON())

        @$select.val(@racer_id)
        @$('img.avatar').attr('src', src)
        @parent.checkGateReady()
        return

    updateTimes: (model) ->
        model.time1='💥' if model.time1 == '0.0000'
        model.time2='💥' if model.time2 == '0.0000'
        model.time3='💥' if model.time3 == '0.0000'
        model.time4='💥' if model.time4 == '0.0000'

        model.time1 = '-.----' if model.time1 == ''
        model.time2 = '-.----' if model.time2 == ''
        model.time3 = '-.----' if model.time3 == ''
        model.time4 = '-.----' if model.time4 == ''

        model.lane1 = '-' if model.lane1 == ''
        model.lane2 = '-' if model.lane2 == ''
        model.lane3 = '-' if model.lane3 == ''
        model.lane4 = '-' if model.lane4 == ''

        @$('.heat-time1').text model.time1 + ' ' + model.lane1
        @$('.heat-time2').text model.time2 + ' ' + model.lane2
        @$('.heat-time3').text model.time3 + ' ' + model.lane3
        @$('.heat-time4').text model.time4 + ' ' + model.lane4


    result: (time) ->
        if @racer_id != -1
            if time != 0
            then @$('.time').text time.toFixed(4)
            else @$('.time').text '💥'
        return


class GroupSelect extends Backbone.View
    tagName: 'optgroup'
    className: () -> "group group-#{@model.get('group')}"
    attributes: () ->
        'label': @model.get('group')

    initialize: (options) ->
        @render()
        @listenTo @model, 'change',  @render, @
        @listenTo @model, 'remove',  @remove, @
        @listenTo @model, 'destroy', @remove, @
        return @

    render: () ->
        @model.toJSON()
        @$el.attr 'label', @model.get('group')
        return @
