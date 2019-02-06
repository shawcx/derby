
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class HeatModal extends Backbone.View
    el: () -> $('#heat-modal')

    initialize: (options) ->
        @render()
        return @

    render: () ->
        @selectA = new RaceSelect
            collection: @collection

        @selectB = new RaceSelect
            collection: @collection

        @$('#heat-container-a').append(@selectA.$el)
        @$('#heat-container-b').append(@selectB.$el)
        return @

    results: (timeA, timeB) ->
        console.log 'results', timeA, timeB
        @selectA.result(timeA)
        @selectB.result(timeB)
        return

module.exports.HeatModal = HeatModal


class RaceSelect extends Backbone.View
    events:
        'change' : 'OnChange'

    initialize: (options) ->
        @render()
        @$select = @$('select')

        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        #@listenTo @collection, 'remove', (racers) =>
        #    $('#racers-count').text(@collection.length)
        #    return
        #@$el.append($('<option value="-1">Empty</option>'))
        return @

    render: () ->
        values =
            lane: 'A'
        @$el.html Templates['heat-select'] values
        return @

    Add: (racer) ->
        @$select.append($("<option value=\"#{ racer.id }\">#{ racer.get('name') }</option>"))
        return

    OnChange: () ->
        racer_id = parseInt(@$select.val())
        if racer_id != -1
            racer = @collection.get(@$select.val())
            @$('img.avatar').attr('src', racer.get('avatar'))
        else
            @$('img.avatar').attr('src', '/static/empty.png')

        return

    result: (time) ->
        @$('.time').text time
        return
