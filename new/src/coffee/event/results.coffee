
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class GroupFilter extends Backbone.View
    el: () -> $('#results-select-group')

    events:
        'click .select-group' : 'OnSelectGroup'

    initialize: (options) ->
        @table = options.table
        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (groups) =>
            groups.forEach @Add, @
            return
        return @

    Add: (group) ->
        btn = new GroupButton
            model: group
        @$el.append(btn.$el)
        return

    OnSelectGroup: (e) ->
        @$el.find('button').removeClass('btn-primary').addClass('btn-secondary')
        $(e.target).removeClass('btn-secondary').addClass('btn-primary')
        @group = $(e.target).data('group')
        @FilterGroup()
        return

    FilterGroup: () ->
        @group = null if @group is 'all'

        count = 0
        @table.racers.forEach (racer) =>
            row = @table.rows[racer.id]
            row.$el.detach()
            if @group and racer.get('group_id') != @group
                return
            @table.$tbody.append(row.$el)
            count++
            return

        if @collection.length and count is 0
        then @table.$tbody.find('tr.no-racers').removeClass('d-none')
        else @table.$tbody.find('tr.no-racers').addClass('d-none')

        return


class GroupButton extends Backbone.View
    tagName: 'button'
    className: 'btn btn-secondary select-group'
    attributes: () ->
        'data-group': @model.id

    initialize: (options) ->
        @render()
        @listenTo @model, 'change',  @render, @
        @listenTo @model, 'remove',  @remove, @
        @listenTo @model, 'destroy', @remove, @
        return @

    render: () ->
        @model.toJSON()
        @$el.text @model.get('group')
        return @


class ResultsTable extends Backbone.View
    el: () -> $('#results-table')

    initialize: (options) ->
        @racers = options.racers
        @groups = options.groups

        @rows   = {}
        @$tbody = @$('tbody')

        @groupFilter = new GroupFilter
            collection: @groups
            table: @

        # bind to the racers collection
        @listenTo @racers, 'add', @Add, @
        @listenTo @racers, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        @listenTo @racers, 'sort', (racers) =>
            racers.forEach (racer) =>
                row = @rows[racer.id]
                row.$el.remove()
                @$tbody.append(row.$el)
                return
            @groupFilter.FilterGroup()
            return

        @listenTo @groups, 'add', () =>
            @$tbody.find('tr.no-groups').addClass('d-none')
            if @racers.length is 0
                @$tbody.find('tr.no-racers').removeClass('d-none')
            else
                @$tbody.find('tr.no-racers').addClass('d-none')

            return
        @listenTo @groups, 'reset', (groups) =>
            if groups.length > 0
                @$tbody.find('tr.no-groups').addClass('d-none')
            else
                @$tbody.find('tr.no-racers').addClass('d-none')
            return

        return @

    Add: (racer) ->
        resultRow = new ResultsRow
            model: racer
            collection: @groups
        @rows[racer.id] = resultRow
        @$tbody.append resultRow.$el
        return

module.exports.ResultsTable = ResultsTable


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

        @stopListening(@group)
        @group = @collection.get(@model.get('group_id'))
        @listenTo @group, 'change', @render, @

        model.group = @group.get('group')

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
            worst = @model.calculateTotal()
            worst = worst.toFixed(4)
            if worst == '10.0000'
                worst = '💥'

            for el,idx in @$el.find('.td-times')
                break if idx is 4
                if $(el).text().startsWith(worst)
                    $(el).css('opacity', '0.5').css('text-decoration', 'line-through')
                    break

        return @
