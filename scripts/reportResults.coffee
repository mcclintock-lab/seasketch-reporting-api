class ReportResults extends Backbone.Collection

  defaultPollingInterval: 3000

  constructor: (@sketch, @deps) ->
    @url = url = "/reports/#{@sketch.id}/#{@deps.join(',')}"
    super()

  poll: () =>
    @fetch {
      success: () =>
        @trigger 'jobs'
        for result in @models
          if result.get('status') not in ['complete', 'error']
            unless @interval
              @interval = setInterval @poll, @defaultPollingInterval
            return
        # all complete then
        window.clearInterval(@interval) if @interval
        if problem = _.find(@models, (r) -> r.get('error')?)
          @trigger 'error', "Problem with #{problem.get('serviceName')} job"
        else
          @trigger 'finished'
      error: (e, res, a, b) =>
        unless res.status is 0
          if res.responseText?.length
            try
              json = JSON.parse(res.responseText)
            catch
              # do nothing
          window.clearInterval(@interval) if @interval
          @trigger 'error', json?.error?.message or 
            'Problem contacting the SeaSketch server'
    }

module.exports = ReportResults
