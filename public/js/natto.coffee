(exports ? this).natto =
  init: ($) ->
    
    w = 1280
    h = 800
    node = undefined
    link = undefined
    root = undefined
    force = undefined
    vis = undefined
    
    update = ->
      nodes = flatten(root)
      links = d3.layout.tree().links(nodes)
      
      # Restart the force layout.
      force.nodes(nodes).links(links).start()
      
      # Update the links
      link = vis.selectAll("line.link").data(links, (d) ->
        d.target.id
      )
      
      # Enter any new links.
      link.enter().insert("svg:line", ".node").attr("class", "link").attr("x1", (d) ->
        d.source.x
      ).attr("y1", (d) ->
        d.source.y
      ).attr("x2", (d) ->
        d.target.x
      ).attr "y2", (d) ->
        d.target.y

      
      # Exit any old links.
      link.exit().remove()
      
      # Update the nodes
      node = vis.selectAll("circle.node").data(nodes, (d) ->
        d.id
      ).style("fill", color)
      node.transition().attr "r", (d) ->
        (if d.children then 4.5 else Math.sqrt(d.size) / 10)

      
      # Enter any new nodes.
      node.enter().append("svg:circle").attr("class", "node").attr("cx", (d) ->
        d.x
      ).attr("cy", (d) ->
        d.y
      ).attr("r", (d) ->
        (if d.children then 4.5 else Math.sqrt(d.size) / 10)
      ).style("fill", color).on("click", click).call force.drag
      
      # Exit any old nodes.
      node.exit().remove()
      return
    
    tick = ->
      link.attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)
      
      node.attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)


    # Color leaf nodes orange, and packages white or blue.
    color = (d) ->
      (if d._children then "#3182bd" else (if d.children then "#c6dbef" else "#fd8d3c"))

    # Toggle children on click.
    click = (d) ->
      if d.children
        d._children = d.children
        d.children = null
      else
        d.children = d._children
        d._children = null
      update()

    # Returns a list of all nodes under the root.
    flatten = (root) ->
      recurse = (node) ->
        if node.children
          node.size = node.children.reduce((p, v) ->
            p + recurse(v)
          , 0)
        node.id = ++i  unless node.id
        nodes.push node
        node.size
      nodes = []
      i = 0
      root.size = recurse(root)
      nodes
    
    d3.json "flare.json", (json) ->
      root = json
      root.fixed = true
      root.x = w / 2
      root.y = h / 2 - 80
     
      force = d3.layout.force().on("tick", tick).charge((d) ->
          (if d._children then -d.size / 100 else -30)
        ).linkDistance((d) ->
          (if d.target._children then 80 else 30)
        ).size([w, h - 160])
      
      vis = d3.select("body").append("svg:svg").attr("width", w).attr("height", h)
     
      update()
      
      return

    return

