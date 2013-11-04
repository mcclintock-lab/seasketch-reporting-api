class JobItem extends Backbone.View
  className: 'reportResult'
  events: {}
  bindings:
    "h6 a":
      observe: "serviceName"
      updateView: true
      attributes: [{
        name: 'href'
        observe: 'serviceUrl'
      }]
    ".startedAt":
      observe: ["startedAt", "status"]
      visible: () ->
        @model.get('status') not in ['complete', 'error']
      updateView: true
      onGet: () ->
        if @model.get('startedAt')
          return "Started " + moment(@model.get('startedAt')).fromNow() + ". "
        else
          ""
    ".status":      
      observe: "status"
      onGet: (s) ->
        switch s
          when 'pending'
            "waiting in line"
          when 'running'
            "running analytical service"
          when 'complete'
            "completed"
          when 'error'
            "an error occurred"
          else
            s
    ".queueLength": 
      observe: "queueLength"
      onGet: (v) ->
        s = "Waiting behind #{v} job"
        if v.length > 1
          s += 's'
        return s + ". "
      visible: (v) ->
        v? and parseInt(v) > 0
    ".errors":
      observe: 'error'
      updateView: true
      visible: (v) ->
        v?.length > 2
      onGet: (v) ->
        if v?
          JSON.stringify(v, null, '  ')
        else
          null

  constructor: (@model) ->
    super()

  render: () ->
    @$el.html """
      <h6><a href="#" target="_blank"></a><span class="status"></span></h6>
      <div>
        <span class="startedAt"></span>
        <span class="queueLength"></span>
        <pre class="errors"></pre>
      </div>
    """
    @stickit()

module.exports = JobItem