enableLayerTogglers = require './enableLayerTogglers.coffee'
round = require('./utils.coffee').round

class RecordSet

  constructor: (@data) ->

  toArray: () ->
    _.map @data.value[0].features, (feature) ->
      feature.attributes

  raw: (attr) ->
    attrs = _.map @toArray(), (row) ->
      row[attr]
    attrs = _.filter attrs, (attr) -> attr != undefined
    if attrs.length is 0
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

  render: () ->
    throw 'render method must be overidden'

  show: () ->
    @$el.show()
    @visible = true

  hide: () ->
    @$el.hide()
    @visible = false

  remove: () =>
    super()
  
  onLoading: () -> # extension point for subclasses

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
    unless results = @results?.get('data')?.results
      throw new Error('No gp results')
    _.filter results, (result) ->
      result.paramName not in ['ResultCode', 'ResultMsg']

  recordSet: (dependency, paramName) ->
    unless dependency in @dependencies
      throw new Error "Unknown dependency #{dependency}"
    dep = _.find @allResults, (result) -> result.get('name') is dependency
    unless dep
      console.log @allResults
      throw new Error "Could not find results for #{dependency}."
    param = _.find dep.get('data').results, (param) -> 
      param.paramName is paramName
    unless param
      throw new Error "Could not find param #{paramName} in #{dependency}"
    new RecordSet(param)

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

module.exports = ReportTab