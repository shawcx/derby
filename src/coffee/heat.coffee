
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

        $('#heat-racer-a').append(@selectA.$el)
        $('#heat-racer-b').append(@selectB.$el)
        return @

module.exports.HeatModal = HeatModal


class RaceSelect extends Backbone.View
    tagName:   'select'
    className: 'form-control'
    attributes:
        name: 'race-select'

    events:
        'changed' : 'OnChange'

    initialize: (options) ->
        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        #@listenTo @collection, 'remove', (racers) =>
        #    $('#racers-count').text(@collection.length)
        #    return

        @$el.append($('<option value="-1">Empty</option>'))
        return @

    Add: (racer) ->
        @$el.append($("<option value=\"#{ racer.id }\">#{ racer.get('name') }</option>"))
        return

    OnChange: () ->
        console.log '...'
        return
