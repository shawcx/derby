
$        = require('jquery')
_        = require('underscore')
Backbone = require('backbone')

class RacerModel extends Backbone.Model
    urlRoot: '/data/racers/'
    idAttribute: 'racer_id'

class RacerCollection extends Backbone.Collection
    model: RacerModel
    url: RacerModel.prototype.urlRoot

module.exports.Model      = RacerModel
module.exports.Collection = RacerCollection


class RacersModal extends Backbone.View
    el: () -> $('#racers-modal')

    initialize: (options) ->
        @$a = @$('.modal-body')

        @listenTo @collection, 'reset', (racers) =>
            racers.forEach (racer, idx) =>
                @Add(racer)
                #console.log idx, JSON.stringify racer.toJSON()
                return
            return

        @listenTo @collection, 'add', (racer) =>
            @Add(racer)
            #console.log ':::', racer.toJSON()
            #console.log 'device session:', session.toJSON()
            #v = new Views.Session
            #    model: session
            #v.deviceView = @
            #@$('.device-sessions').prepend v.$el
            #@$('.session-count').text @model.sessions.length
            return

        return @

    Add: (racer) ->
        racerRow = new RacerRow
            model: racer
        console.log '...'
        @$a.append racerRow.$el
        return

module.exports.RacersModal = RacersModal


class RacerRow extends Backbone.View
    className: 'racerRow'

    #events:
    #    'click'  : 'OnClick'

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

    #OnClick: () ->
    #    $radio = @$('input[name="persona"]')
    #    value = $radio.prop('checked')
    #    $radio.prop('checked', not value)
    #    return


class AddRacerModal extends Backbone.View
    el: () -> $('#add-racer-modal')

    events:
        'show.bs.modal'         : 'OnShowModal'
        'submit form'           : 'OnRacerSave'
        'click #avatarVid'      : 'OnClickVideo'
        'click #avatarImg'      : 'OnClickImage'

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
            console.log 'no avatar...'
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
            @video.videoHeight,                     # src width (using height prop for square)
            @video.videoHeight,                     # src height
            0,                                      # dst offset x
            0,                                      # dst offset y
            @vidSize,                               # dst width
            @vidSize                                # dst height
            )

        avatar = canvas.toDataURL('image/jpeg', 0.9)
        @racer.set('avatar', avatar)
        $('#avatarImg').attr('src', avatar).show()
        $('#avatarVid').hide()
        return

    OnClickImage: () ->
        $('#avatarImg').hide()
        $('#avatarVid').show()
        @racer.unset('avatar')

module.exports.AddRacerModal = AddRacerModal
