# Logic Programming Examples in ECLiPSe Prolog

Five examples written in [ECLiPSe Prolog](https://eclipseclp.org/), in two parts:

- **Part 1: Classic Prolog** (`prolog_examples.ecl`): recursion, list processing and search over a knowledge base. The examples are a Roman-numeral converter and a ferry route planner.
- **Part 2: Constraint Logic Programming** (`clp_examples.ecl`): combinatorial optimisation with finite-domain constraints and branch-and-bound search. The examples are a team-scheduling problem, a 1-D packing problem and a resource-constrained production plan.

> **Note:** This is based on the work by Ilias Sakellariou, Nikolaos Vasileiadis, Petros Kefalas and Dimosthenis Stamatis, [*Logic Programming Techniques*](https://repository.kallipos.gr/handle/11419/777) (Kallipos repository).

---

## Part 1: Classic Prolog

**Techniques used:** recursion · `append/3` for list decomposition · `member/2` · `findall/3` and `sort/2` for collecting answers · term inspection with `=..` · cut (`!`) to control backtracking

### Example 1: Roman numerals (`toroman/2`)

Converts a positive integer into Roman numerals, returned as a list of lowercase symbols.

The symbols are `i`=1, `v`=5, `x`=10, `l`=50, `c`=100, `d`=500 and `m`=1000. Values normally add up (`xxi` = 21). The exceptions are the six subtractive pairs: `iv`=4, `ix`=9, `xl`=40, `xc`=90, `cd`=400 and `cm`=900. The predicate must return exactly one answer.

```prolog
?- toroman(18, L).
L = [x, v, i, i, i]

?- toroman(2015, L).
L = [m, m, x, v]
```

**Approach:** one clause per value range, from smallest to largest. Each clause emits the largest symbol (or subtractive pair) that fits, then recurses on the remainder. Inputs from 1 up to 3999 are supported, the usual range for Roman numerals.

### Example 2: Ferry route planner

A small knowledge base describes summer ferry lines between Greek islands. Each line lists the ship, the days it sails and the ports it visits in order:

```prolog
line(anemos,  [mon,tue,wed,fri], [athens,syros,paros,naxos]).
line(maria,   [mon,tue,thu],     [naxos,amorgos,santorini]).
line(minos,   [tue,fri],         [paros,syros,andros,tinos]).
line(pelagos, [mon,wed,fri],     [amorgos,ios,milos]).
```

A second set of facts gives each ship's arrival time at every port. A ship leaves a port one hour after arriving there.

```prolog
sched(anemos, [athens(06), syros(10), paros(12), naxos(13)]).
sched(maria,  [naxos(13), amorgos(17), santorini(19)]).
...
```

The program answers these questions:

| Predicate | What it does |
|-----------|--------------|
| `connects(Dep, Des, Day, Info)` | Is there a direct ship from `Dep` to `Des` on `Day`? Ships only sail forward along their route. Returns `ship(Name, Dep, Des)`. |
| `find_trip(Dep, Des, Day, Trip)` | Finds a journey that may need changes of ship, as a list of `ship/3` legs. A ship appears at most once per trip. |
| `arrival(Leg, Time)` / `departure(Leg, Time)` | Arrival time at the destination and departure time from the origin of a leg. |
| `valid_trip(Trip)` | Checks that each connection is feasible: every leg arrives before the next one leaves. |
| `all_ports(Ports)` | Sorted list of every port in the network. |
| `connection_ports(Ports)` | Ports served by at least two different lines, i.e. where you can change ship. |

```prolog
?- find_trip(athens, amorgos, mon, T).
T = [ship(anemos, athens, naxos), ship(maria, naxos, amorgos)]

?- departure(ship(maria, naxos, santorini), D).
D = 14

?- connection_ports(L).
L = [amorgos, naxos, paros, syros]
```

**Approach:** route direction is enforced with `append(_, [Dep|Rest], Ports), member(Des, Rest)`, so the destination must come after the origin in the port list. Multi-leg trips are built recursively, keeping track of the ports visited and ships used, so no ship is used twice and the search always terminates. Times are read by decomposing schedule terms with `=..`. The two list-of-ports queries combine `findall/3` with `sort/2` to remove duplicates.

---

## Part 2: Constraint Logic Programming

**Techniques used:** `ic` finite-domain constraints · `element/3` lookups · `alldifferent/1` · `cumulative/4` resource constraints · `bb_min/3` branch-and-bound optimisation · `findall/3` to build models from Prolog facts

### Example 3: Team scheduling (`assign_teams/2`)

Six teams must each take exactly one of six sub-tasks. How long a task takes depends on which team does it, and each team only becomes available after a given time:

| Team | Duration of task 1–6 | Available after |
|------|----------------------|-----------------|
| A | 3, 4, 1, 3, 5, 6  | 5 |
| B | 4, 1, 3, 2, 1, 2  | 6 |
| C | 2, 1, 4, 5, 2, 1  | 2 |
| D | 3, 3, 2, 1, 9, 4  | 4 |
| E | 6, 2, 1, 3, 4, 7  | 0 |
| F | 6, 2, 3, 8, 9, 11 | 3 |

The project cost is a weighted sum of each team's completion time:

```
Cost = 14·C_A + 3·C_B + 6·C_C + 2·C_D + 8·C_E + 10·C_F
```

**Goal:** decide which team takes which task so that total cost is minimal.

```prolog
?- assign_teams(Workers, Cost).
% Workers = [T_A, T_B, ..., T_F]   (task number taken by each team)
```

**Model:** one decision variable per team (the task it takes), `alldifferent/1` so every task is covered once, `element/3` to look up the matching duration, and `bb_min/3` to minimise the weighted completion cost.

**Extension:** add conditional rules, e.g. *if team A takes task 2, team B must take task 4*, and *if team D takes task 3, team F must take task 5*. These map naturally to reified implication constraints:

```prolog
(A #= 2) => (B #= 4),
(D #= 3) => (F #= 5),
```

---

### Example 4: Warehouse loading (`store_loading/2`)

Five crates have to be placed in a warehouse 400 cm wide. Crates can't be stacked, but several can sit side by side as long as their combined width fits:

| Crate | Width (cm) | Length (m) |
|-------|-----------:|-----------:|
| A | 150 | 2 |
| B | 180 | 1 |
| C | 230 | 3 |
| D | 130 | 2 |
| E | 200 | 3 |

**Goal:** find where along the warehouse each crate starts (distance from the entrance) so that the total length used is as small as possible.

```prolog
?- store_loading(Positions, Length).
```

**Model:** this is a scheduling problem in disguise. A crate's length plays the role of a task duration and its width the role of resource usage, with the warehouse width (400) as capacity. A single `cumulative/4` constraint captures it, and `bb_min/3` minimises the furthest crate end (`maxlist/2`).

---

### Example 5: Food-production plan (`my_workplan/2`)

A food workshop has orders with delivery deadlines, and each product needs a fixed number of working days at a fixed number of hours per day:

```prolog
order(product(a), 24).        workload(product(a), 8, 3).
order(product(b), 16).        workload(product(b), 9, 5).
order(product(c), 19).        workload(product(c), 9, 3).
order(product(d), 22).        workload(product(d), 8, 4).
```

`workload(P, Days, Hours)` means product `P` needs `Days` days of work at `Hours` hours per day. The workshop has 8 working hours per day and can work on several products at once, provided their hours that day add up to at most 8.

**Goal:** finish each product as close to its delivery date as possible (without missing it), and report when production of each product starts and how many days from now work must begin.

```prolog
?- my_workplan(Plan, FirstStart).
% Plan = [start(product(a), Sa), start(product(b), Sb), ...]
```

**Model:** the facts are gathered with `findall/3`, deadlines become constraints on each product's end day, `cumulative/4` enforces the 8-hour daily capacity, and branch-and-bound pushes completion times as late as possible (it minimises the negated sum of end days). The earliest start is then taken with `minlist/2`.

---

## Running the code

Requires [ECLiPSe](https://eclipseclp.org/). Part 2 uses the `ic`, `ic_global`, `ic_edge_finder` and `branch_and_bound` libraries, so it won't run in SWI-Prolog as-is.

### Using the TkECLiPSe GUI

TkECLiPSe is the graphical environment that comes with ECLiPSe. On Windows, the installer adds it to the Start menu.

1. **Install ECLiPSe:** download the installer for your OS from the [ECLiPSe download page](https://eclipseclp.org/download.html) and run it.
2. **Open TkECLiPSe** from the Start menu (or run `tkeclipse` from a terminal on Linux/macOS).
3. **Compile a file:** choose **File → Compile…** and select `prolog_examples.ecl` or `clp_examples.ecl`.
   The **Output** pane at the bottom should show a `... compiled` message with no errors.
4. **Select the module:** in the drop-down next to the **Query Entry** box, make sure **`eclipse`** is selected.
   If another module is selected (e.g. `development_support`), queries fail with *"calling an undefined procedure"*.
5. **Run a query:** type a query into **Query Entry** (the final `.` is optional) and click **run** or press Enter.
   For `prolog_examples.ecl`:
   ```prolog
   toroman(2015, L)
   find_trip(athens, ios, mon, T)
   all_ports(P)
   ```
   For `clp_examples.ecl`:
   ```prolog
   assign_teams(W, C)
   store_loading(V, L)
   my_workplan(W, S)
   ```
6. **Read the results:** the variable bindings appear in the **Results** pane. For the Part 2 examples, the `Found a solution with cost ...` lines from branch-and-bound appear in the **Output** pane.
   Click **more** to ask for another solution.
7. **After editing the source:** click **make** (or compile again) before re-running a query.

### Using the command line

```bash
eclipse
[eclipse 1]: [prolog_examples].
[eclipse 2]: toroman(2015, L).
[eclipse 3]: [clp_examples].
[eclipse 4]: assign_teams(W, C).
[eclipse 5]: store_loading(V, L).
[eclipse 6]: my_workplan(W, S).
[eclipse 7]: halt.
```

Or as a one-liner:

```bash
eclipse -f clp_examples.ecl -e "assign_teams(W, C), writeln(W-C)"
```
