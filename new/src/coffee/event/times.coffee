
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')

class TimeModel extends Backbone.Model
    urlRoot: '/times/'
    idAttribute: 'time_id'

class TimeCollection extends Backbone.Collection
    model: TimeModel
    url: TimeModel.prototype.urlRoot

module.exports.Model      = TimeModel
module.exports.Collection = TimeCollection
