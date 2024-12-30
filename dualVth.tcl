proc swap_to_hvt {} {
    foreach_in_collection cell [get_cells] {
        set ref_name [get_attribute $cell ref_name]

        set library_name "CORE65LPHVT"
        regsub {_LL} $ref_name "_LH" new_ref_name
        size_cell $cell "${library_name}/${new_ref_name}"
    }
}

proc swap_cell_to_lvt {cell} {
    set ref_name [get_attribute $cell ref_name]

    set library_name "CORE65LPLVT"
    regsub {_LH} $ref_name "_LL" new_ref_name
    size_cell $cell "${library_name}/${new_ref_name}"
}

# the function compare each name of the cell of the circuit with the name in the list, and if there is a match the cell is swapped
proc swap_list_to_hvt {list_lvt_cells} {
    set cells [get_cells]
    set library_name "CORE65LPHVT"
    foreach celli $list_lvt_cells {
        foreach_in_collection cellj [get_cells] {
            set full_name [get_attribute $cellj full_name]
            set ref_name [get_attribute $cellj ref_name]
            if {$celli == $full_name} {
                regsub {_LL} $ref_name "_LH" new_ref_name
                size_cell $cellj "${library_name}/${new_ref_name}"
            }  
        }
    }
} 

# the function compare each name of the cell of the circuit with the name in the list, and if there is a match the cell is swapped
proc swap_list_to_lvt {list_hvt_cells} {
    set cells [get_cells]
    set library_name "CORE65LPLVT"
    foreach celli $list_hvt_cells {
        foreach_in_collection cellj [get_cells] {
            set full_name [get_attribute $cellj full_name]
            set ref_name [get_attribute $cellj ref_name]
            if {$celli == $full_name} {
                regsub {_LH} $ref_name "_LL" new_ref_name
                size_cell $cellj "${library_name}/${new_ref_name}"
            }
        }
    }
}

proc get_cells_names {list_of_cells} {
    set cells_name ""
    foreach sublist $list_of_cells {
        lappend cells_name [lindex $sublist 0]
    }
    return $cells_name
}

proc check_contest_constraints {slackThreshold maxFanoutEndpointCost} {
    update_timing -full

    # check slack
    set most_critical_slack [get_attribute [get_timing_paths] slack]
    puts "slack: $most_critical_slack\n"
    if {$most_critical_slack < 0} {
        return 0
    }

    # check fanout endpoint cost
    foreach_in_collection cell [get_cells] {
    set paths [get_timing_paths -through $cell -nworst 1 -max_paths 10000 -slack_lesser_than $slackThreshold]
    set cell_fanout_endpoint_cost 0.0
    foreach_in_collection path $paths {
        set this_cost [expr $slackThreshold - [get_attribute $path slack]]
        set cell_fanout_endpoint_cost [expr $cell_fanout_endpoint_cost + $this_cost]
    }

    if {$cell_fanout_endpoint_cost >= $maxFanoutEndpointCost} {
        set cell_name [get_attribute $cell full_name]
        set cell_ref_name [get_attribute $cell ref_name]
        error "Cell $cell_name ($cell_ref_name) has fanout endpoint cost of $cell_fanout_endpoint_cost (>= $maxFanoutEndpointCost)."
        return 0
    }
    }

    return 1
}

proc sort_cells_by_slack {list_of_cells} {
    set sorted_cells ""

    foreach_in_collection cell $list_of_cells {
        set cell_path [get_timing_paths -through $cell]
        set cell_slack [get_attribute $cell_path slack]
        set cell_name [get_attribute $cell full_name]
        lappend sorted_cells "$cell_name $cell_slack"
    }
    set sorted_cells [lsort -real -decreasing -index 1 $sorted_cells]
    return $sorted_cells
    # smallest slack is more critical
}


proc dualVth {slackThreshold maxFanoutEndpointCost} {
    global leakage_initial
    set iteration_fail 0
    set iteration_success 0

    set cells [get_cells]
    set num_cells [sizeof_collection [get_cells]]
    # we did a lot of different tests and the percentage of 2% seems to be the better
    set num_cells_to_change [expr $num_cells/100 * 2] 

    # sort cells
    set sorted_cells [sort_cells_by_slack $cells]  ;# the function returns a list of sorted cells
    set sorted_cells [get_cells_names $sorted_cells] ;# the function returns a list with only the names of the cells, sorted by slack

    # puts "list of ordered cells: $sorted_cells"

    set pointer_sublist 0
    
    # cost function: normalized power
    set leakage_final [get_attribute [current_design] leakage_power]
    set normalized_power [expr ($leakage_final / $leakage_initial)]

    while {$normalized_power >= 0.8} {
        set cells_to_change [lrange $sorted_cells $pointer_sublist [expr $pointer_sublist + $num_cells_to_change]]

        # puts "the cells to swap are: $cells_to_change"

        swap_list_to_hvt $cells_to_change
        
        # if the constraints are not met, we go back to LVT and we try to swap to HVT only the half, and so on
        # if the constraints are met we continue to iterate
        # in any case, after a predefined number of iteration we stop in order to reduce the CPU time
        if {[check_contest_constraints $slackThreshold $maxFanoutEndpointCost] == 0} {
            swap_list_to_lvt $cells_to_change

            if {$iteration_success >= 2} {
                return
            }

            set num_cells_to_change [expr ($num_cells_to_change / 2)]
            incr iteration_fail
            if {$iteration_fail == 3} {
                return
            } 
            
        } else {
            incr pointer_sublist $num_cells_to_change
            incr pointer_sublist 1

            incr iteration_success
            if {$iteration_success == 3} {
                return
            } 
        }
        set leakage_final [get_attribute [current_design] leakage_power]
        set normalized_power [expr ($leakage_final / $leakage_initial)]  
    }

    return 1
}