class ReportResults extends Backbone.Collection

  defaultPollingInterval: 5000

  constructor: (@sketch, @deps) ->
    @url = url = "/reports/#{@sketch.id}/#{@deps.join(',')}"
    super()

  poll: () =>
    @fetch {
      success: () =>
        @trigger 'jobs'
        for result in @models
          if result.get('status') != 'complete'
            unless @interval
              @interval = setInterval @poll, @defaultPollingInterval
            return
        # all complete then
        window.clearInterval(@interval) if @interval
        if _.find(@models, (r) -> r.error?)
          @trigger 'error', 'JOB_ERROR'
        else
          @trigger 'finished'
      error: () =>
        window.clearInterval(@interval) if @interval
        @trigger 'error', 'JOB_SUBMISSION'
    }

module.exports = ReportResults
