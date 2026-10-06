/* Example 1: Roman numerals */

/*Note that modern use of Roman numerals involves relatively
small numbers (theoretically, up to 3,999)*/

toroman(A,_):- A < 0, !, fail.
toroman(0,R):- !, append([],[],R).
toroman(A,R):-	A < 4, !,ATemp is A - 1,toroman(ATemp,RTemp),append([i],RTemp,R).
toroman(A,R):-	A = 4, !,append([i,v],[],R).
toroman(A,R):-	A = 5, !,append([v],[],R).	
toroman(A,R):-	A < 9, !,ATemp is A - 5,toroman(ATemp,RTemp),append([v],RTemp,R).	
toroman(A,R):-	A = 9, !,append([i,x],[],R).	
toroman(A,R):-	A < 40, !,ATemp is A - 10,toroman(ATemp,RTemp),append([x],RTemp,R).	
toroman(A,R):-	A < 50, !,ATemp is A - 40,toroman(ATemp,RTemp),append([x,l],RTemp,R).	
toroman(A,R):-	A < 90, !,ATemp is A - 50,toroman(ATemp,RTemp),append([l],RTemp,R).	
toroman(A,R):-	A < 100, !,ATemp is A - 90,toroman(ATemp,RTemp),append([x,c],RTemp,R).	
toroman(A,R):-	A < 400, !,ATemp is A - 100,toroman(ATemp,RTemp),append([c],RTemp,R).	
toroman(A,R):-	A < 500, !,ATemp is A - 400,toroman(ATemp,RTemp),append([c,d],RTemp,R).	
toroman(A,R):-	A < 900, !,ATemp is A - 500,toroman(ATemp,RTemp),append([d],RTemp,R).	
toroman(A,R):-	A < 1000, !,ATemp is A - 900,toroman(ATemp,RTemp),append([c,m],RTemp,R).	
toroman(A,R):-	A < 4000, !,ATemp is A - 1000,toroman(ATemp,RTemp),append([m],RTemp,R).

/* Example 2: Ferry route planner */

line(anemos,[mon,tue,wed,fri],[athens,syros,paros,naxos]).
line(maria,[mon,tue,thu],[naxos,amorgos,santorini]).
line(minos,[tue,fri],[paros,syros,andros,tinos]).
line(pelagos,[mon,wed,fri],[amorgos,ios,milos]).

sched(anemos,[athens(06),syros(10),paros(12),naxos(13)]).
sched(maria,[naxos(13),amorgos(17),santorini(19)]).
sched(minos,[paros(13),syros(15),andros(17),tinos(19)] ).
sched(pelagos,[amorgos(15),ios(17),milos(20)]).



connects(Dep,Des,Day,Info):-
	Dep \= Des,
	line(ShipName,Days,Ports),
	append(_,[Dep|L],Ports),
	member(Des,L),
	member(Day,Days),
	Info = ship(ShipName,Dep,Des).
	
	
find_trip(Dep,Des,Day,Trip):-
	Dep \= Des,
	find_trip(Dep,Des,Day,[Dep],[],Trip).

/* find_trip/6 keeps the ports already visited and the ships already used,
   so the search never revisits a port or reuses a ship (and always terminates). */

/* direct connection with a ship not used yet */
find_trip(Dep,Des,Day,_Visited,UsedShips,[Info]):-
	connects(Dep,Des,Day,Info),
	Info = ship(Ship,_,_),
	not(member(Ship,UsedShips)).

/* take a ship to an intermediate port and continue from there */
find_trip(Dep,Des,Day,Visited,UsedShips,[ship(Ship,Dep,Stop)|Rest]):-
	line(Ship,Days,Ports),
	member(Day,Days),
	not(member(Ship,UsedShips)),
	append(_,[Dep|L],Ports),
	member(Stop,L),
	Stop \= Des,
	not(member(Stop,Visited)),
	find_trip(Stop,Des,Day,[Stop|Visited],[Ship|UsedShips],Rest).
	
arrival(ship(Ship,Dep,Des),Arrival):-
	connects(Dep,Des,_,Info),
	member(ship(Ship,Dep,Des),[Info]),
	!,
	sched(Ship,Schedule),
	member(X,Schedule),
	X =.. [H|[T]],
	H == Des,
	Arrival = T.
	
	
departure(ship(Ship,Dep,Des),DepTime):-
	connects(Dep,Des,_,Info),
	member(ship(Ship,Dep,Des),[Info]),
	!,
	sched(Ship,Schedule),
	member(X,Schedule),
	X =.. [H|[T]],
	H == Dep,
	DepTime is T+1.
	


valid_trip([]).

valid_trip([_|[]]).

valid_trip(Trip):-
	member(L1,Trip),
	member(L2,Trip),
	L1 \= L2,
	L1 =.. [H|F1],	/*H = ship because L1 is of the form : ship(ShipName,Dep,Des)*/	
	member(Ship1,F1),
	member(Dep1,F1),
	member(Des1,F1),
	sort([Ship1,Dep1,Des1],Uniques1),
	length(Uniques1,3),
	L2 =.. [H|F2],
	member(Ship2,F2),
	member(Dep2,F2),
	member(Des2,F2),
	sort([Ship2,Dep2,Des2],Uniques2),
	length(Uniques2,3),
	!,
	departure(ship(Ship2,Dep2,Des2),DepTime),
	arrival(ship(Ship1,Dep1,Des1),ArrivalTime),
	ArrivalTime =< DepTime,
	append([L1],Rest,Trip),
	valid_trip(Rest).
	
all_ports(AllUniquePorts):-
	findall(X,line(_,_,X),L),
	aux_append(L,Ports),
	sort(Ports,AllUniquePorts).
	

connection_ports(ConnectionPorts):-	
	findall(PortX,(line(Y,_,PortsX),line(Z,_,PortsZ),Y \= Z,member(PortX,PortsX),member(PortZ,PortsZ),PortX == PortZ),L),
	sort(L,ConnectionPorts).


	
aux_append([H|[]],R):-
	append(H,[],R).
	
	
aux_append([H|T],R):-
	aux_append(T,P),
	append(H,P,R).
	

	
	
	
	

