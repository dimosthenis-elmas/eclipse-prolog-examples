:-use_module(library(ic)).
:-use_module(library(branch_and_bound)).
:-use_module(library(ic_edge_finder)).

/* Example 3: Team scheduling */
assign_teams(Teams,TotalCost):-
	Teams = [A,B,C,D,E,F],
	Starts = [StA,StB,StC,StD,StE,StF],
	Starts #:: 0..inf,
	
	StA #>5,
	StB #>6,
	StC #>2,
	StD #>4,
	StE #>0,
	StF #>3,
	
	labeling(Starts),
	
	element(IA,[1,2,3,4,5,6],A),
	element(IB,[1,2,3,4,5,6],B),
	element(IC,[1,2,3,4,5,6],C),
	element(ID,[1,2,3,4,5,6],D),
	element(IE,[1,2,3,4,5,6],E),
	element(IF,[1,2,3,4,5,6],F),
	
	element(IA,[3,4,1,3,5,6],DurA),
	element(IB,[4,1,3,2,1,2],DurB),
	element(IC,[2,1,4,5,2,1],DurC),
	element(ID,[3,3,2,1,9,4],DurD),
	element(IE,[6,2,1,3,4,7],DurE),
	element(IF,[6,2,3,8,9,11],DurF),
	
	CostA #= 14*(StA + DurA - 1),
	CostB #= 3*(StB + DurB - 1),
	CostC #= 6*(StC + DurC - 1),
	CostD #= 2*(StD + DurD - 1),
	CostE #= 8*(StE + DurE - 1),
	CostF #= 10*(StF + DurF - 1),
	
	alldifferent(Teams),	
	TotalCost #= CostA + CostB + CostC + CostD + CostE + CostF,	
	bb_min(labeling(Teams),TotalCost,_).
	
	
/*--------------------------------------------------------------------------*/

/* Example 4: Warehouse loading */

store_loading(Starts,Length):-
	Lengths = [2,1,3,2,3],
	Widths = [150,180,230,130,200],
	Starts = [StA,StB,StC,StD,StE],
	Starts #:: 0..inf,
	
	EndA #= StA + 2,
	EndB #= StB + 1,
	EndC #= StC + 3,
	EndD #= StD + 2,
	EndE #= StE + 3,
	
	cumulative(Starts,Lengths,Widths,400),
	ic_global:maxlist([EndA,EndB,EndC,EndD,EndE],Length),
	bb_min(labeling(Starts),Length,bb_options{strategy:restart}).
	
/*----------------------------------------------------------------------------*/

/* Example 5: Food-production plan */

outputParser([],[],[]).
outputParser([Hp|Tp],[Hs|Ts],[Fact|To]):-
	Fact =.. [start,Hp,Hs],
	outputParser(Tp,Ts,To).

order(product(a),24).
order(product(b),16).
order(product(c),19).
order(product(d),22).

workload(product(a),8,3).
workload(product(b),9,5).
workload(product(c),9,3).
workload(product(d),8,4).

state_ends([],[],[],[]).
state_ends([H_Starts|T_Starts],[H_Days|T_Days],[H_Deliv|T_Deliv],[H_Ends|T_Ends]):-
	H_Ends #= H_Starts + H_Days,
	H_Ends #< H_Deliv,
	state_ends(T_Starts,T_Days,T_Deliv,T_Ends).

my_workplan(StartsOut,MinStart):-
	findall(D,order(_,D),Deliveries),
	findall(W,workload(_,W,_),WorkDays),
	findall(H,workload(_,_,H),WorkHours),
	
	length(WorkDays,N),
	length(Starts,N),	
	Starts #:: 0..inf,
	
	state_ends(Starts,WorkDays,Deliveries,Ends),
	fd_global:sumlist(Ends,SumOfEnds),
	MinusSumOfEnds #= (-1)*SumOfEnds,
	
	cumulative(Starts,WorkDays,WorkHours,8),	
	bb_min(labeling(Starts),MinusSumOfEnds,_),
	findall(P,order(P,_),Products),
	outputParser(Products,Starts,StartsOut),
	ic_global:minlist(Starts,MinStart).
	
	
	
	
	
	
	
	
	
	
	