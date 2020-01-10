
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')


class GroupModel extends Backbone.Model
    urlRoot: '/groups/'
    idAttribute: 'group_id'


class GroupCollection extends Backbone.Collection
    model: GroupModel
    url: GroupModel.prototype.urlRoot


module.exports.Model      = GroupModel
module.exports.Collection = GroupCollection


class GroupsModal extends Backbone.View
    el: () -> $('#groups-modal')

    events:
        'click #groups-add-group' : 'OnAddGroup'

    initialize: (options) ->
        @render()
        return @

    render: () ->
        return @

    reset: () ->
        return

    OnAddGroup: () ->
        console.log 'add'
        return

module.exports.GroupsModal = GroupsModal
