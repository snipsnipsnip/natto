(exports ? this).natto =
  init: ($) ->
    width = 960
    height = 2200

    cluster = d3.layout.cluster().size([height, width - 160])

    diagonal = d3.svg.diagonal()
        .projection((d) -> [d.y, d.x])

    svg = d3.select("body").append("svg")
        .attr("width", width)
        .attr("height", height)
      .append("g")
        .attr("transform", "translate(40,0)")

    d3.json "/flare.json", (error, root) ->
      nodes = cluster.nodes(root)
      links = cluster.links(nodes)

      link = svg.selectAll(".link")
          .data(links)
        .enter().append("path")
          .attr("class", "link")
          .attr("d", diagonal)

      node = svg.selectAll(".node")
          .data(nodes)
        .enter().append("g")
          .attr("class", "node")
          .attr("transform", (d) -> "translate(" + d.y + "," + d.x + ")")

      node.append("circle")
          .attr("r", 4.5)

      node.append("text")
          .attr("dx", (d) -> d.children ? -8 : 8)
          .attr("dy", 3)
          .style("text-anchor", (d) -> d.children ? "end" : "start")
          .text((d) -> d.name)

    d3.select(self.frameElement).style("height", height + "px")

    return

