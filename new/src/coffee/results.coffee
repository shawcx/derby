
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class ResultsTable extends Backbone.View
    el: () -> $('#results-table')

    initialize: (options) ->
        @rows   = {}
        @$tbody = @$('tbody')

        @denFilter = new DenFilter
            table: @

        # bind to the racers collection
        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        @listenTo @collection, 'sort', (racers) =>
            racers.forEach (racer) =>
                row = @rows[racer.id]
                row.$el.remove()
                @$tbody.append(row.$el)
                return
            @denFilter.FilterDen()
            return
        return @

    Add: (racer) ->
        resultRow = new ResultsRow
            model: racer
        @rows[racer.id] = resultRow
        @$tbody.append resultRow.$el
        return

module.exports.ResultsTable = ResultsTable

class DenFilter extends Backbone.View
    el: () -> $('#results-select-den')

    events:
        'click .select-den' : 'OnSelectDen'

    initialize: (options) ->
        @table = options.table
        return @

    OnSelectDen: (e) ->
        @$el.find('button').removeClass('btn-primary').addClass('btn-secondary')
        $(e.target).removeClass('btn-secondary').addClass('btn-primary')
        @den = $(e.target).data('den')
        @FilterDen()

    FilterDen: () ->
        @den = null if @den is 'all'
        @table.collection.forEach (racer) =>
            row = @table.rows[racer.id]
            row.$el.remove()
            if @den and racer.get('den') != @den
                return
            @table.$tbody.append(row.$el)
            return
        return


class ResultsRow extends Backbone.View
    tagName: 'tr'
    className: 'resultRow'

    initialize: () ->
        _.bindAll @, 'render'
        @render()
        @listenTo @model, 'change',  @render, @
        @listenTo @model, 'remove',  @remove, @
        @listenTo @model, 'destroy', @remove, @
        return @

    render: () ->
        model = @model.toJSON()

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

        @$el.html Templates['result-row'] model

        if @model.get('count') == 4
            worse = @model.calculateTotal()
            worse = worse.toFixed(4)
            if worse == '10.0000'
                worse = '💥'

            for el,idx in @$el.find('.td-times')
                break if idx is 4
                if $(el).text().startsWith(worse)
                    $(el).css('opacity', '0.5').css('text-decoration', 'line-through')
                    break

        return @
