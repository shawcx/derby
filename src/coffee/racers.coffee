
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')

class RacerModel extends Backbone.Model
    urlRoot: '/racers/'
    idAttribute: 'racer_id'
    defaults:
        count: 0
        time1: ''
        time2: ''
        time3: ''
        time4: ''
        lane1: ''
        lane2: ''
        lane3: ''
        lane4: ''
        total: ''

    calculateTotal: () ->
        times = []
        for idx in [1..4]
            t = @get('time'+idx)
            t = parseFloat(t)
            if t == 0
                times.push(10)
            else if t
                times.push(t)
            # else ignore

        sortNumber = (a, b) -> a - b
        times.sort(sortNumber)
        times = times.slice(0,3)

        sumNumber = (a, b) -> a + b
        total = times.reduce(sumNumber, 0)
        @set('total', total.toFixed(4))
        return

class RacerCollection extends Backbone.Collection
    model: RacerModel
    url: RacerModel.prototype.urlRoot

module.exports.Model      = RacerModel
module.exports.Collection = RacerCollection


class RacersModal extends Backbone.View
    el: () -> $('#racers-modal')

    initialize: (options) ->
        # reference to the body of the racers modal
        @$body = @$('#racers-body')
        # bind to the racers collection
        #@listenTo @collection, 'add', (racer) =>
        #    @Add(racer)
        #    return
        @listenTo @collection, 'add', @Add, @
        @listenTo @collection, 'reset', (racers) =>
            racers.forEach @Add, @
            return
        @listenTo @collection, 'remove', (racers) =>
            $('#racers-count').text(@collection.length)
            return
        return @

    Add: (racer) ->
        # update the count in the navbar
        $('#racers-count').text(@collection.length)
        # create a new racer row
        racerRow = new RacerRow
            model: racer
        # and append it to the modal body
        @$body.append racerRow.$el
        return

module.exports.RacersModal = RacersModal


class RacerRow extends Backbone.View
    className: 'racerRow'

    events:
        'click .delete-racer'  : 'OnDelete'

    initialize: () ->
        _.bindAll @, 'render'
        @render()
        @listenTo @model, 'change', @render
        @listenTo @model, 'remove', () =>
            @remove()
            return
        return @

    render: () ->
        model = @model.toJSON()
        #model.created = (new Date(model.created * 1000)).shortdate()
        @$el.html Templates['racer-row'] model
        return @

    OnDelete: () ->
        really = confirm("Remove #{ @model.get('name') }?")
        return if not really
        @model.destroy wait: true
        return


class AddRacerModal extends Backbone.View
    el: () -> $('#add-racer-modal')

    events:
        'show.bs.modal'          : 'OnShowModal'
        'submit form'            : 'OnRacerSave'
        'click #add-racer-reset' : 'reset'
        'click #avatarVid'       : 'OnClickVideo'
        'click #avatarVid'       : 'OnClickVideo'
        'click #avatarImg'       : 'OnClickImage'

    initialize: (options) ->
        @reset()
        return @

    reset: () ->
        @racer = new RacerModel

        $('#add-racer-name').val('')
        $('#add-racer-den').val(null)
        $('#add-racer-car').val('')

        $('#avatarImg').hide()
        $('#avatarVid').show()
        $('#add-racer-save').prop('disabled', true)

        return

    OnShowModal: () ->
        @vidSize = $('#avatarVid').height()
        if not @video
            constraints =
                video: true
            @video = document.querySelector('video')
            navigator.mediaDevices.getUserMedia(constraints).then (stream) =>
                @video.srcObject = stream
                return
        return

    OnRacerSave: (evt) ->
        if not @racer.has('avatar')
            alert('No picture was taken')
            return cancelEvent(evt)
        @racer.save {
                name: $('#add-racer-name').val()
                den:  $('#add-racer-den').val()
                car:  $('#add-racer-car').val()
            },{
                wait: true,
                success: () =>
                    @collection.add @racer
                    @reset()
                    return
                error: (model,xhr) =>
                    alert(xhr.responseText)
                    return
            }
        return cancelEvent(evt)

    OnClickVideo: () ->
        constraints =
          video:
            width:
              min: 320
            height:
                min: 240

        canvas = document.createElement('canvas')
        canvas.width  = @vidSize
        canvas.height = @vidSize
        canvas.getContext('2d').drawImage(
            @video,                                 # src
            @video.videoWidth - @video.videoHeight, # src offset x
            0,                                      # src offset y
            @video.videoHeight,                     # src width (use height for square)
            @video.videoHeight,                     # src height
            0,                                      # dst offset x
            0,                                      # dst offset y
            @vidSize,                               # dst width
            @vidSize                                # dst height
            )

        avatar = canvas.toDataURL('image/jpeg', 0.9)
        @racer.set('avatar', avatar)
        $('#avatarVid').hide()
        $('#avatarImg').attr('src', avatar).show()
        $('#add-racer-save').prop('disabled', false)
        return

    OnClickImage: () ->
        $('#avatarImg').hide()
        $('#avatarVid').show()
        $('#add-racer-save').prop('disabled', true)
        @racer.unset('avatar')

module.exports.AddRacerModal = AddRacerModal
