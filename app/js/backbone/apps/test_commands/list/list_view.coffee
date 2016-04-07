@App.module "TestCommandsApp.List", (List, App, Backbone, Marionette, $, _) ->

  class List.Command extends App.Views.ItemView
    template: "test_commands/list/_default"

    ui:
      wrapper:  ".command-wrapper"
      method:   ".command-method"
      tooltips: "[data-toggle='tooltip']"
      # pause:    ".fa-pause"

    modelEvents:
      "change:state"     : "render"
      "change:visible"   : "render"
      "change:alias"     : "render"
      "change:chosen"    : "chosenChanged"
      "change:highlight" : "highlightChanged"

    triggers:
      # "click @ui.pause"   : "pause:clicked"
      "mouseenter"        : "command:mouseenter"
      "mouseleave"        : "command:mouseleave"

    events:
      "click"             : "clicked"

    onShow: ->
      @$el
        .addClass("command-type-#{@model.get("type")}")
        .addClass("command-name-#{@model.displayName()}")

      if @model.hasParent()
        @$el.removeClass("command-parent").addClass("command-child")
      else
        @$el.removeClass("command-child").addClass("command-parent")

      @$el.addClass "command-event" if @model.isEvent()

    onBeforeRender: ->
      if _.isObject(@ui.tooltips) and @ui.tooltips.length
        @ui.tooltips.tooltip("destroy")

    onRender: ->
      @ui.method.css "padding-left", @model.get("indent")

      ## add or remove command-pending whether we're in pending state
      @$el.toggleClass "command-pending", @model.state("pending")

      ## add or remove command-failed whether we have an error
      @$el.toggleClass "command-failed", @model.state("failed")

      @model.triggerCommandCallback("onRender", @$el)

      @ui.tooltips.tooltip({container: "body", delay: 250})

    clicked: (e) ->
      e.stopPropagation()

      @displayConsoleMessage()

      console.clear?()

      @model.getConsoleDisplay (args) ->
        console.log.apply(console, args)

    displayConsoleMessage: ->
      width  = @$el.outerWidth()
      offset = @$el.offset()

      div = $("<div>", class: "command-console-message")
      div.text("Printed output to your console!")

      ## center this guy in the middle of our command
      div.appendTo($("body"))
        .css
          top: offset.top
          left: offset.left
          marginLeft: (width / 2) - (div.innerWidth() / 2)
      div
        .fadeIn(180)
          .delay(120)
            .fadeOut 300, -> $(@).remove()

    chosenChanged: (model, value, options) ->
      @$el.toggleClass "active", value

    highlightChanged: (model, value, options) ->
      @$el.toggleClass "highlight", value

    onDestroy: ->
      ## stop the model from listening
      ## to its command log's events
      @model.stopListening()

      @ui.tooltips.tooltip("destroy")

  class List.Hook extends App.Views.CompositeView
    template: "test_commands/list/_hook"
    tagName: "li"
    className: "hook-item"
    childView: List.Command
    childViewContainer: "ul"

    ui:
      "commands" : ".commands-container"
      "caret"    : "i.fa-caret-down"
      "ellipsis" : "i.fa-ellipsis-h"
      "failed"   : ".hook-failed"

    modelEvents:
      "change:visible" : "visibleChanged"
      "change:failed"  : "failedChanged"

    events:
      "click .hook-name" : "hookClicked"

    initialize: ->
      @collection = @model.get("commands")

    hookClicked: (e) ->
      @model.toggle()
      e.preventDefault()
      e.stopPropagation()

    visibleChanged: (model, value, options) ->
      @ui.commands.toggleClass "hidden", !value
      @changeIconDirection(!value)
      @displayEllipsis(!value)

    changeIconDirection: (bool) ->
      klass = if bool then "right" else "down"
      @ui.caret.removeClass().addClass("fa fa-caret-#{klass}")

    displayEllipsis: (bool) ->
      @ui.ellipsis.toggleClass "hidden", !bool

    failedChanged: (model, bool, options) ->
      @ui.failed.toggleClass "hidden", !bool

  class List.Empty extends App.Views.ItemView
    template: "test_commands/list/_empty"

  class List.Hooks extends App.Views.CollectionView
    tagName: "ul"
    className: "hooks-container"
    childView: List.Hook
    emptyView: List.Empty

    isEmpty: -> @renderEmpty