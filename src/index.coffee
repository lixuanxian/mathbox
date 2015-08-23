# Global constructor
mathBox = (options) ->
  options ?= {}

  three = THREE.Bootstrap options
  three.install 'mathbox' if !three.MathBox?

  three.mathbox ? three

# Just because
window.π = Math.PI
window.τ = π * 2
window.e = Math.E

# Namespace
window.MathBox = exports
window.mathBox = exports.mathBox = mathBox
exports.version = '2'

# Load context and export namespace
Context = require './context'
exports[k] = v for k, v of Context.Namespace

# Threestrap plugin
THREE.Bootstrap.registerPlugin 'mathbox',
  defaults:
    init: true
    inspect: true

  listen: ['ready', 'pre', 'render', 'update', 'post', 'resize'],

  # Install meta-API
  install: (three) ->
    inited = false
    @first = true

    three.MathBox =
      # Init the mathbox context
      init: (options) =>
        return if inited
        inited = true

        scene  = options?.scene  || @options.scene  || three.scene
        camera = options?.camera || @options.camera || three.camera

        @context = new Context three.renderer, scene, camera

        # Enable handy destructuring
        @context.api.three   = three.three   = three
        @context.api.mathbox = three.mathbox = @context.api

        @context.init()
        @context.resize three.Size

      # Destroy the mathbox context
      destroy: () =>
        return if !inited
        inited = false

        @context.destroy()

        delete three.mathbox
        delete @context.api.three
        delete @context

      object: () => @context?.scene.root

  uninstall: (three) ->
    three.MathBox.destroy()
    delete three.MathBox

  ready: (event, three) ->
    if @options.init
      three.MathBox.init()

      setTimeout () =>
        @context.warmup()
        @inspect three if @options.inspect

  inspect: (three) ->
    three.mathbox.inspect()

    fmt = (x) ->
      out = []
      while x >= 1000
        out.unshift ("000" + (x % 1000)).slice(-3)
        x = Math.floor(x / 1000)
      out.unshift x
      out.join ','

    info = three.renderer.info.render
    console.log(fmt(info.faces) + ' faces  ',
                fmt(info.vertices) + ' vertices  ',
                fmt(info.calls) + ' draw calls');

  # Hook up context events
  resize: (event, three) ->
    @context?.resize three.Size

  pre: (event, three) ->
    @context?.pre(three.Time)

  update: (event, three) ->
    @context?.update()

    if (camera = @context?.camera) and
       camera != three.camera

      three.camera = camera

  render: (event, three) ->
    @context?.render()

  post: (event, three) ->
    @context?.post()
