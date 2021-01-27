"""
Assumes x,y points go around the polygon in one direction.
Credits: https://rosettacode.org/wiki/Shoelace_formula_for_polygonal_area#Julia
"""
shoelacearea(x, y) =
    abs(sum(i * j for (i, j) in zip(x, append!(y[2:end], y[1]))) -
        sum(i * j for (i, j) in zip(append!(x[2:end], x[1]), y))) / 2
