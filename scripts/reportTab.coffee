enableLayerTogglers = require './enableLayerTogglers.coffee'
round = require('./utils.coffee').round
ReportResults = require './reportResults.coffee'
t = require('../templates/templates.js')
templates =
  reportLoading: t['node_modules/seasketch-reporting-api/reportLoading']
JobItem = require './jobItem.coffee'
CollectionView = require('views/collectionView')

class RecordSet

  constructor: (@data, @tab, @sketchClassId) ->

  toArray: () ->
    if @sketchClassId
      data = _.find @data.value, (v) =>
        v.features?[0]?.attributes?['SC_ID'] is @sketchClassId
      unless data
        throw "Could not find data for sketchClass #{@sketchClassId}"
    else
      if _.isArray @data.value
        data = @data.value[0]
      else
        data = @data.value
    _.map data.features, (feature) ->
      feature.attributes

  raw: (attr) ->
    attrs = _.map @toArray(), (row) ->
      row[attr]
    attrs = _.filter attrs, (attr) -> attr != undefined
    if attrs.length is 0
      console.log @data
      @tab.reportError "Could not get attribute #{attr} from results"
      throw "Could not get attribute #{attr}"
    else if attrs.length is 1
      return attrs[0]
    else
      return attrs

  int: (attr) ->
    raw = @raw(attr)
    if _.isArray(raw)
      _.map raw, parseInt
    else
      parseInt(raw)

  float: (attr, decimalPlaces=2) ->
    raw = @raw(attr)
    if _.isArray(raw)
      _.map raw, (val) -> round(val, decimalPlaces)
    else
      round(raw, decimalPlaces)

  bool: (attr) ->
    raw = @raw(attr)
    if _.isArray(raw)
      _.map raw, (val) -> val.toString().toLowerCase() is 'true'
    else
      raw.toString().toLowerCase() is 'true'

class ReportTab extends Backbone.View
  name: 'Information'
  dependencies: []

  initialize: (@model, @options) ->
    # Will be initialized by SeaSketch with the following arguments:
    #   * model - The sketch being reported on
    #   * options
    #     - .parent - the parent report view
    #        call @options.parent.destroy() to close the whole report window
    @app = window.app
    _.extend @, @options
    @reportResults = new ReportResults(@model, @dependencies)
    @listenToOnce @reportResults, 'error', @reportError
    @listenToOnce @reportResults, 'jobs', @renderJobDetails
    @listenToOnce @reportResults, 'jobs', @reportJobs
    @listenTo @reportResults, 'finished', _.bind @render, @
    @listenToOnce @reportResults, 'request', @reportRequested

  render: () ->
    throw 'render method must be overidden'

  show: () ->
    @$el.show()
    @visible = true
    if @dependencies?.length and !@reportResults.models.length
      @reportResults.poll()
    else if !@dependencies?.length
      @render()
      @$('[data-attribute-type=UrlField] .value, [data-attribute-type=UploadField] .value').each () ->
        text = $(@).text()
        html = []
        for url in text.split(',')
          if url.length
            name = _.last(url.split('/'))
            html.push """<a target="_blank" href="#{url}">#{name}</a>"""
        $(@).html html.join(', ')


  hide: () ->
    @$el.hide()
    @visible = false

  remove: () =>
    window.clearInterval @etaInterval
    @stopListening()
    super()

  reportRequested: () =>
    @$el.html templates.reportLoading.render({})

  reportError: (msg, cancelledRequest) =>
    unless cancelledRequest
      if msg is 'JOB_ERROR'
        @showError 'Error with specific job'
      else
        @showError msg

  showError: (msg) =>
    @$('.progress').remove()
    @$('p.error').remove()
    @$('h4').text("An Error Occurred").after """
      <p class="error" style="text-align:center;">#{msg}</p>
    """

  reportJobs: () =>
    unless @maxEta
      @$('.progress .bar').width('100%')
    @$('h4').text "Analyzing Designs"

  startEtaCountdown: () =>
    if @maxEta
      _.delay () =>
        @reportResults.poll()
      , (@maxEta + 1) * 1000
      _.delay () =>
        @$('.progress .bar').css 'transition-timing-function', 'linear'
        @$('.progress .bar').css 'transition-duration', "#{@maxEta + 1}s"
        @$('.progress .bar').width('100%')
      , 500

  renderJobDetails: () =>
    maxEta = null
    for job in @reportResults.models
      if job.get('etaSeconds')
        if !maxEta or job.get('etaSeconds') > maxEta
          maxEta = job.get('etaSeconds')
    if maxEta
      @maxEta = maxEta
      @$('.progress .bar').width('5%')
      @startEtaCountdown()

    @$('[rel=details]').css('display', 'block')
    @$('[rel=details]').click (e) =>
      e.preventDefault()
      @$('[rel=details]').hide()
      @$('.details').show()
    for job in @reportResults.models
      item = new JobItem(job)
      item.render()
      @$('.details').append item.el

  getResult: (id) ->
    results = @getResults()
    result = _.find results, (r) -> r.paramName is id
    unless result?
      throw new Error('No result with id ' + id)
    result.value

  getFirstResult: (param, id) ->
    result = @getResult(param)
    try
      return result[0].features[0].attributes[id]
    catch e
      throw "Error finding #{param}:#{id} in gp results"

  getResults: () ->
    results = @reportResults.map((result) -> result.get('result').results)
    unless results?.length
      throw new Error('No gp results')
    _.filter results, (result) ->
      result.paramName not in ['ResultCode', 'ResultMsg']

  recordSet: (dependency, paramName, sketchClassId=false) ->
    unless dependency in @dependencies
      throw new Error "Unknown dependency #{dependency}"
    dep = @reportResults.find (r) -> r.get('serviceName') is dependency
    unless dep
      console.log @reportResults.models
      throw new Error "Could not find results for #{dependency}."
    param = _.find dep.get('result').results, (param) ->
      param.paramName is paramName
    unless param
      console.log dep.get('data').results
      throw new Error "Could not find param #{paramName} in #{dependency}"
    new RecordSet(param, @, sketchClassId)

  enableTablePaging: () ->
    @$('[data-paging]').each () ->
      $table = $(@)
      pageSize = $table.data('paging')
      rows = $table.find('tbody tr').length
      pages = Math.ceil(rows / pageSize)
      if pages > 1
        $table.append """
          <tfoot>
            <tr>
              <td colspan="#{$table.find('thead th').length}">
                <div class="pagination">
                  <ul>
                    <li><a href="#">Prev</a></li>
                  </ul>
                </div>
              </td>
            </tr>
          </tfoot>
        """
        ul = $table.find('tfoot ul')
        for i in _.range(1, pages + 1)
          ul.append """
            <li><a href="#">#{i}</a></li>
          """
        ul.append """
          <li><a href="#">Next</a></li>
        """
        $table.find('li a').click (e) ->
          e.preventDefault()
          $a = $(this)
          text = $a.text()
          if text is 'Next'
            a = $a.parent().parent().find('.active').next().find('a')
            unless a.text() is 'Next'
              a.click()
          else if text is 'Prev'
            a = $a.parent().parent().find('.active').prev().find('a')
            unless a.text() is 'Prev'
              a.click()
          else
            $a.parent().parent().find('.active').removeClass 'active'
            $a.parent().addClass 'active'
            n = parseInt(text)
            $table.find('tbody tr').hide()
            offset = pageSize * (n - 1)
            $table.find("tbody tr").slice(offset, n*pageSize).show()
        $($table.find('li a')[1]).click()

      if noRowsMessage = $table.data('no-rows')
        if rows is 0
          parent = $table.parent()
          $table.remove()
          parent.removeClass 'tableContainer'
          parent.append "<p>#{noRowsMessage}</p>"

  enableLayerTogglers: () ->
    enableLayerTogglers(@$el)

  getChildren: (sketchClassId) ->
    _.filter @children, (child) -> child.getSketchClass().id is sketchClassId


module.exports = ReportTab
