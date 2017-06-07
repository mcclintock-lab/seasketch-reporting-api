module.exports = (el, rasterLayersList) ->
  $el = $ el
  app = window.app



  togglers = $el.find('a[data-raster-url]')
  # Set initial state
  for toggler in togglers.toArray()
    $toggler = $(toggler)
    url = $toggler.data('raster-url')
    width = $toggler.data('width')
    height = $toggler.data('height')
    extent = $toggler.data('extent').split(',')
    toggled = $toggler.data('toggled')
    if !url or !width or !height or !extent
      throw new Error("Raster links must include data-raster-url, data-width, data-height, and data-extent attributes")
    layer = new esri.layers.MapImageLayer({visible: toggled})
    mapImage = new esri.layers.MapImage('extent': { 'xmin': extent[0], 'ymin': extent[1], 'xmax': extent[2], 'ymax': extent[3], 'spatialReference': { 'wkid': 3857 }},
    'href': url)
    toc = $ """
      <div class="tableOfContents">
      <div class="tableOfContentsItem" data-dp-status="" data-type="sketch" data-loading="false">
        <div unselectable="on" class="item" data-visibility="#{toggled}" data-checkoffonly="" data-hidechildren="no" data-selected="false">
          <span unselectable="on" class="loading">&nbsp;</span>
          <span unselectable="on" class="expander"></span>
          <span unselectable="on" class="visibility"></span>
          <span unselectable="on" class="icon" style=""></span>
          <span unselectable="on" class="name">#{$toggler.text()}</span>
          <span unselectable="on" class="context"></span>
          <span unselectable="on" class="description" style="display: none;"></span>
        </div>
      </div>
      </div>
      """
    $toggler.replaceWith(toc)
    $toggler = toc.find('.tableOfContentsItem');
    layer.addImage(mapImage);
    rasterLayersList.push layer
    window.app.projecthomepage.map.addLayer(layer)
    $toggler.data('layer', layer)
    $toggler.on 'click', (e) =>
      item = $(e.target).closest('.tableOfContentsItem')
      layer = item.data('layer')
      item.find('.item').attr('data-visibility', !layer.visible)
      layer.setVisibility(!layer.visible)
      e.preventDefault()
