ReportTab = require './reportTab.coffee'
templates = require 'api/templates'
partials = []
for key, val of templates
  partials[key.replace('node_modules/seasketch-reporting-api/', '')] = val

class GenericAttributesTab extends ReportTab
  name: 'Attributes'
  className: 'genericAttributes'
  template: templates['node_modules/seasketch-reporting-api/genericAttributes']

  render: () ->
    context =
      sketch: @model.forTemplate()
      sketchClass: @sketchClass.forTemplate()
      attributes: @model.getAttributes()
      admin: @project.isAdmin window.user
    @$el.html @template.render(context, partials)


module.exports = GenericAttributesTab