import * as d3 from 'd3';
import * as cloud from 'd3-cloud';

$(document).on('turbo:load', function() {

  const id = '#tag-cloud';
  const size = [1200, 1200];

  // Only load data on pages where we have a place to put it
  if($(id).length > 0) {
    fetch('keyword_counts.json')
      .then(response => response.json())
      .then(data => tagCloud(id, size, data));
  }

});

function tagCloud(id, size, words) {

  const fill = d3.scaleOrdinal(d3.schemeCategory10);

  const layout = cloud()
    .size(size)
    .words(words)
    .padding(5)
    .font("Impact")
    .fontSize(function(d) { return d.size; })
    .on("end", draw);

  layout.start();

  function draw(words) {
    var svg = d3
      .select(id)
      .append("svg")
      .attr("width", layout.size()[0])
      .attr("height", layout.size()[1])
      .append("g")
      .attr("transform", "translate(" + layout.size()[0] / 2 + "," + layout.size()[1] / 2 + ")")
      .selectAll("text")
      .data(words)
      .enter().append("text")
      .style("font-size", function(d) { return d.size + "px"; })
      .style("font-family", "Impact")
      .style("fill", function (d, i) { return fill(i); })
      .style("cursor", "pointer")
      .attr("text-anchor", "middle")
      .attr("transform", function(d) {
        return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")";
      })
      .on("click", function (d) {
        location.href = `keyword/${this.textContent}`;
      })
      .text(function(d) { return d.text; });
  }
}
