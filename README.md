# Dual-Vth Optimization Script for Low-Power Implementation

This script provides a methodology for optimizing power consumption in digital circuit designs by selectively swapping cells between Low-Vth (LVT) and High-Vth (HVT) libraries. It uses timing and fanout constraints to ensure the design remains functional while minimizing leakage power.

## Features
- **Cell Library Swapping**: Switch between HVT and LVT libraries to optimize power and performance.
- **Constraint Checking**: Verifies timing and fanout constraints after each iteration.
- **Critical Path Prioritization**: Targets cells on critical paths to balance performance and power.
- **Iterative Optimization**: Adjusts cell selection dynamically to converge on an optimal solution.

---

## Script Functions

### Cell Swapping
- `swap_to_hvt`: Replaces all cells with their corresponding HVT counterparts.
- `swap_cell_to_lvt`: Swaps a single cell to its LVT counterpart.
- `swap_list_to_hvt`: Swaps specific cells to HVT based on a provided list of full cell names.
- `swap_list_to_lvt`: Swaps specific cells to LVT based on a provided list of full cell names.

### Cell Sorting and Management
- `get_cells_names`: Extracts cell names from a list of cell attributes.
- `sort_cells_by_slack`: Sorts cells based on their slack values in descending order (most critical first).

### Constraints Checking
- `check_contest_constraints`: Ensures timing slack and fanout endpoint cost are within defined thresholds.

### Dual-Vth Optimization
- `dualVth`: Iteratively swaps cells between HVT and LVT libraries to minimize power while satisfying constraints. The function:
  - Sorts cells by slack.
  - Targets the most critical cells for swapping.
  - Adjusts the number of cells swapped based on success or failure of constraints validation.
  - Stops iterating once normalized leakage power drops below 0.8 or after predefined iteration limits.

---

## Parameters

### `dualVth` Function
- `slackThreshold`: The maximum allowable slack threshold for timing paths.
- `maxFanoutEndpointCost`: The maximum allowable fanout endpoint cost for individual cells.

---

## Example Usage

1. **Initialize Leakage Power**:
   ```tcl
   set leakage_initial [get_attribute [current_design] leakage_power]
   ```

2. **Run Optimization**:
   ```tcl
   dualVth 0.01 10.0
   ```

3. **Output**:
   The script will report critical slack violations and fanout endpoint costs if constraints are not met, and it will terminate if the constraints cannot be satisfied within the iteration limits.

---

## Notes
- **Library Naming Convention**: Assumes specific naming patterns for cell libraries (`_LL` for LVT and `_LH` for HVT). Adjust the `regsub` commands if your naming conventions differ.
- **Cell Selection**: Targets the top 2% of critical cells by slack during each iteration. This percentage can be tuned in the `dualVth` function.
- **Iteration Limits**: The script stops after 3 successful iterations or 3 failed attempts to meet constraints.

---

## Requirements
- TCL scripting environment compatible with your EDA tool.
- Cell libraries named according to the conventions (`CORE65LPLVT` and `CORE65LPHVT`).

---

## License
This script is provided under the MIT License. Use and modify freely while crediting the original author.

