// @ts-check
import periodHoverElementEventHandlers from "./eventHandlers";
import * as d3 from "d3";
import { TimePeriod } from "../../types";

function selectEl(): d3.Selection<HTMLElement, TimePeriod, HTMLElement, any> {
    return d3.select("#hoverInfo");
}

function createBlank() {
    d3.select("body")
        .append("div")
        .on("mouseout", periodHoverElementEventHandlers.handleMouseOut)
        .style("position", "absolute")
        .style("transform", "translateY(5px)")
        .attr("class", "hoverInfo")
        .attr("id", "hoverInfo")
        .call((enter) => {
            enter.append("img");
            enter.append("div").attr("class", "title");
            enter.append("div").attr("class", "desc");
        });
}

function updateInfo(
    selection: d3.Selection<HTMLElement, TimePeriod, HTMLElement, any>,
    period: TimePeriod
) {
    selection.select("img").attr("src", period.topic.thumbnail);
    selection
        .select(".title")
        .text(period.topic.title)
        .on("click", () => periodHoverElementEventHandlers.handleClick(period));
    selection.select(".desc").text(period.topic.description);
}

const HoverInfoElement = { createBlank, updateInfo, selectEl };
export default HoverInfoElement;
