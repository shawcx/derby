
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class HeatModal extends Backbone.View
    el: () -> $('#heat-modal')

    events:
        'click #swapLanes' : 'OnSwapLanes'

    initialize: (options) ->
        @render()
        return @

    render: () ->
        @selectA = new RaceSelect
            collection: @collection
            lane: 'A'

        @selectB = new RaceSelect
            collection: @collection
            lane: 'B'

        @$('#heat-container-a').append(@selectA.$el)
        @$('#heat-container-b').append(@selectB.$el)
        return @

    OnSwapLanes: () ->
        newB = @selectA.racer_id
        newA = @selectB.racer_id
        @selectA.set(newA)
        @selectB.set(newB)
        return

    results: (timeA, timeB) ->
        @selectA.result(timeA)
        @selectB.result(timeB)

        if timeA > timeB
            console.log 'A is the winner'
        else if timeB > timeA
            console.log 'B is the winner'
        else if timeA == timeB
            console.log 'it is a tie!'
        else
            console.error 'unreachable state', timeA, timeB
            return

        return

module.exports.HeatModal = HeatModal


class RaceSelect extends Backbone.View
    events:
        'change' : 'OnChange'

    initialize: (options) ->
        @racer_id = -1
        @lane = options.lane
        @render()
        @$select = @$('select')

        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        return @

    render: () ->
        values =
            lane: @lane
        @$el.html Templates['heat-select'] values
        return @

    Add: (racer) ->
        @$select.append($("<option value=\"#{ racer.id }\">#{ racer.get('name') }</option>"))
        return

    OnChange: () ->
        console.log 'changed...'
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
        return

    result: (time) ->
        @$('.time').text time.toFixed(4)
        return
