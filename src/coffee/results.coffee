
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class ResultsTable extends Backbone.View
    el: () -> $('#results-table')

    initialize: (options) ->
        @$tbody = @$('tbody')

        # bind to the racers collection
        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        return @

    Add: (racer) ->
        resultRow = new ResultsRow
            model: racer
        @$tbody.append resultRow.$el
        return

module.exports.ResultsTable = ResultsTable


class ResultsRow extends Backbone.View
    tagName: 'tr'
    className: 'resultRow'

    #events:
    #    'click .delete-racer'  : 'OnDelete'

    initialize: () ->
        _.bindAll @, 'render'
        @render()
        @listenTo @model, 'change',  @render
        @listenTo @model, 'remove',  @remove
        @listenTo @model, 'destroy', @remove
        return @

    render: () ->
        model = @model.toJSON()

        model.time1='😞' if model.time1 == '0.0000'

        #model.created = (new Date(model.created * 1000)).shortdate()
        @$el.html Templates['result-row'] model
        return @

    #OnDelete: () ->
    #    really = confirm("Remove #{ @model.get('name') }?")
    #    return if not really
    #    @model.destroy wait: true
    #    return

