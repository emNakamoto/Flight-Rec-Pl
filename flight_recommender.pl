:- use_module(api_call).
:- use_module(filter).
:- use_module(library(lists)).

%based off of geographyq.pl from class

[api_call].
[filter].
%https://www.iata.org/en/publications/directories/code-search/

%What is a flight from HND to JFK under 900 dollars between June and July?
%What is the cheapest flight from HND to JFK under 900 dollars between June and July?
%What is the earliest flight from PAR to YVR starting from 10 dollars in September?
%Is there a flight between 100 and 800 dollars from ICN to NRT before August 8, 2021?
%What flights are there between January and March from YVR to SYD over 300 dollars?
%Are there any flights after May 25, 2021 from BKK to TPE between 400 and 800 dollars?

%does not make sense to say
%What is a flight after january, need to give a day

%to run:
%q(Ans).

%--- functions to ask user ---

% get_constraints_from_question(Q,C) is true if C is the constraints from Q
get_constraints_from_question(Q,C) :-
question(Q,End,C,[]),
member(End,[[],['?'],['.']]).

%based on the adjective given, filter results received
handle_adj(cheapest,Ans,Ans2) :-
    compare_multiple_res_price(Ans,Ans2).
handle_adj(earliest,Ans,Ans2) :-
    earliest_res_flight(Ans,Ans2).
handle_adj(none,Ans,Ans).

% ask(Q,C) calls api to answer question Q, and also gives back the constraints it found
ask(Q,C) :-
    get_constraints_from_question(Q,C),
    remove_adj(C,ADJ,C_list),
    get_api_results(C_list,Data),
    get_results(Data,Ans),
    handle_adj(ADJ,Ans,Ans2),
    parse_list_flights(Ans2).

%remove_adj, the adjective is not going to be used in the API call, but keep track of what was removed
%to filter results
remove_adj(C,cheapest,C_list) :-
member(cheapest,C),
delete(C,cheapest,C_list).
remove_adj(C,earliest,C_list) :-
member(earliest,C),
delete(C,earliest,C_list).
remove_adj(C,none,C) :-
\+ member(earliest,C),
\+ member(cheapest,C).

%get the destination from the input
get_dest([],_).
get_dest([destination(_,D)|_],D).
get_dest([time_range(_,_)|T],D) :- get_dest(T,D).
get_dest([price_range(_,_)|T],D) :- get_dest(T,D).
get_dest([earliest|T],D) :- get_dest(T,D).
get_dest([cheapest|T],D) :- get_dest(T,D).


%call the api to see hotels by the destinattion
check_hotels(yes,C) :-
    get_dest(C,Dst),
    get_api_hotel(Dst,Data),
    get_hotel_results(Data,R),
    print_hotels(R).
check_hotels('Yes',C) :-
    get_dest(C,Dst),
    get_api_hotel(Dst,Data),
    get_hotel_results(Data,R),
    print_hotels(R).
check_hotels(no,_).
check_hotels('No',_).

%call the check_hotels function
hotel_call([H|_],Constraints) :-
    check_hotels(H, Constraints).

% To get the input from a line:
q() :-
    write("Ask me about flights ∠(ᐛ 」∠)＿ : "), flush_output(current_output),
    readln(Ln),
    ask(Ln,Constraints),
    write("Would you like hotel suggestions? (yes/no)"), flush_output(current_output),
    readln(L2),
    hotel_call(L2,Constraints).

% ------------- functions to parse input ------------------

% A noun phrase is a determiner followed by adjectives followed
% by a noun followed by an optional connecting phrase and modifying phrase:
flight_query(L0,L5,C0,C5) :-
det(L0,L1,C0,C1),
adjectives(L1,L2,C1,C2),
noun(L2,L3,C2,C3),
cp(L3,L4,C3,C4),
mp(L4,L5,C4,C5).


% Determiners (articles) are ignored in this oversimplified example.
% They do not provide any extra constraints.
det([the | L],L,C,C).
det([a | L],L,C,C).
det(['The' | L],L,C,C).
det(['A' | L],L,C,C).
det(L,L,C,C).


% adjectives(L0,L2,Entity,C0,C2) is true if
% L0-L2 is a sequence of adjectives imposes constraints C0-C2 on Entity
adjectives(L0,L2,C0,C2) :-
adj(L0,L1,C0,C1),
adjectives(L1,L2,C1,C2).
adjectives(L,L,C,C).

%connecting phrase cp(L3,L4,Entity,C3,C4) is either "are", or "are there"
cp([are | L],L,C,C).
cp([are,there | L],L,C,C).
cp(L,L,C,C).


% An optional modifying phrase / relative clause is either
% a list of constraints for the flight
% nothing
mp(L0,L2,C0,C2) :-
conditional(L0,L1,C0,C1),
mp(L1,L2,C1,C2).
mp([for|L0],L2,C0,C2) :-
conditional(L0,L1,C0,C1),
mp(L1,L2,C1,C2).
mp(L,L,C,C).



% accept a price range. The API only takes a max price, but for future, we might want to sort through results
conditional([from,A,to,B | L],L,[destination(A,B)|C],C).
conditional([from,A,Next | L],L,[destination(A,any)|C],C) :- dif(Next,to).
conditional([departing,from,A,Next | L],L,[destination(A,any)|C],C) :- dif(Next,to).
conditional([leaving,from,A,Next | L],L,[destination(A,any)|C],C) :- dif(Next,to).
conditional([between,X,and,Y,dollars | L],L,[price_range(X,Y)|C],C).
conditional([starting,from,X,dollars | L],L,[price_range(X,any)|C],C).
conditional([over,X,dollars | L],L,[price_range(X,any)|C],C).
conditional([under,X,dollars | L],L,[price_range(0,X)|C],C).

%times with between will take the first of each month unless specified
conditional([between,Time1,and,Time2 | L],L,[time_range(T1,T2)|C],C) :-
possible_year(Time1,Y),
get_ISO_date(Time1,1,Y,T1),
get_ISO_date(Time2,1,Y,T2).
conditional([before,Time | L],L,[time_range(any,T)|C],C) :- prev_month(Time,M), possible_year(M,Y), get_ISO_date(M,31,Y,T).
conditional([in,Time | L],L,[time_range(T1,T2)|C],C) :-
last_day(Time,LD),
possible_year(Time,Y),
get_ISO_date(Time,1,Y,T1),
get_ISO_date(Time,LD,Y,T2).

%dates are written like "January 5, 2021" or "January 2021"
%in the in Month Year condition, just give a date that will work for any month at current time
conditional([between,M1,D1,',',Y1,and,M2,D2,',',Y2 | L],L,[time_range(T1,T2)|C],C) :-
get_ISO_date(M1,D1,Y1,T1),
get_ISO_date(M2,D2,Y2,T2).
conditional([after,M,D,',',Y | L],L,[time_range(T,any)|C],C) :- get_ISO_date(M,D,Y,T).
conditional([before,M,D,',',Y | L],L,[time_range(any,T)|C],C) :- prev_month(M,Month), get_ISO_date(Month,D,Y,T).


% DICTIONARY

translate_month('January',"01").
translate_month(january,"01").
translate_month('February',"02").
translate_month(february,"02").
translate_month('March',"03").
translate_month(march,"03").
translate_month('April',"04").
translate_month(april,"04").
translate_month('May',"05").
translate_month(may,"05").
translate_month('June',"06").
translate_month(june,"06").
translate_month('July',"07").
translate_month(july,"07").
translate_month('August',"08").
translate_month(august,"08").
translate_month('September',"09").
translate_month(september,"09").
translate_month('October',"09").
translate_month(october,"10").
translate_month('November',"11").
translate_month(november,"11").
translate_month('December',"12").
translate_month(decembere,"12").

possible_year('January',2022).
possible_year(january,2022).
possible_year('February',2022).
possible_year(february,2022).
possible_year('March',2022).
possible_year(march,2022).
possible_year('April',2022).
possible_year(april,2022).
possible_year('May',2021).
possible_year(may,2021).
possible_year('June',2021).
possible_year(june,2021).
possible_year('July',2021).
possible_year(july,2021).
possible_year('August',2021).
possible_year(august,2021).
possible_year('September',2021).
possible_year(september,2021).
possible_year('October',2021).
possible_year(october,2021).
possible_year('November',2021).
possible_year(november,2021).
possible_year('December',2021).
possible_year(decembere,2021).

last_day('January',31).
last_day(january,31).
last_day('February',28).
last_day(february,28).
last_day('March',31).
last_day(march,31).
last_day('April',30).
last_day(april,30).
last_day('May',31).
last_day(may,31).
last_day('June',30).
last_day(june,30).
last_day('July',31).
last_day(july,31).
last_day('August',31).
last_day(august,31).
last_day('September',30).
last_day(september,30).
last_day('October',31).
last_day(october,31).
last_day('November',30).
last_day(november,30).
last_day('December',31).
last_day(decembere,31).

prev_month('January',december).
prev_month(january,december).
prev_month('February',january).
prev_month(february,january).
prev_month('March',february).
prev_month(march,february).
prev_month('April',march).
prev_month(april,march).
prev_month('May',april).
prev_month(may,april).
prev_month('June',may).
prev_month(june,may).
prev_month('July',june).
prev_month(july,june).
prev_month('August',july).
prev_month(august,july).
prev_month('September',august).
prev_month(september,august).
prev_month('October',september).
prev_month(october,september).
prev_month('November',october).
prev_month(november,october).
prev_month('December',november).
prev_month(decembere,november).

%convert day from number to string, if it is less than 10, 0 needs to be added to front
%this will work for days as well as year because there is no way our year will be less than 10 AD
convert_date(D,S) :-
D>=10,
number_string(D,S).
convert_date(D,S) :-
D<10,
number_string(D,N),
string_concat("0", N, S).

%get_ISO_date is called with (January, 4, 2021)
get_ISO_date(M,D,Y,Res) :-
convert_date(D,Day),
convert_date(Y,Year),
translate_month(M,Month),
string_concat(Year,"-",YS),
string_concat(YS,Month,YM),
string_concat(YM,"-",MS),
string_concat(MS,Day,Res).


% adj(L0,L1,Entity,C0,C1) is true if L0-L1
% is an adjective that imposes constraints C0-C1 Entity
adj([cheapest | L],L, [cheapest|C],C).
adj([earliest | L],L, [earliest|C],C).
adj([first | L],L, [earliest|C],C).

%flight and flights are the nouns that will be given, we will not use these
noun([flight | L],L,C,C).
noun([flights | L],L,C,C).

% question(Question,QR,Entity) is true if Query provides an answer about Entity to Question
question(['Is',there | L0],L1,C0,C1) :-
flight_query(L0,L1,C0,C1).
question(['What',is | L0],L1,C0,C1) :-
flight_query(L0,L1,C0,C1).
question(['What',are | L0],L1,C0,C1) :-
flight_query(L0,L1,C0,C1).
question(['What' | L0],L1,C0,C1) :-
flight_query(L0,L1,C0,C1).
question(['Are',there | L0],L1,C0,C1) :-
flight_query(L0,L1,C0,C1).
question(['Are',there,any | L0],L1,C0,C1) :-
flight_query(L0,L1,C0,C1).


%possible constraints
%[price_range(50, 100), destination('YVR', 'NRT'),time_range("2021-03-03", "2021-06-18")]

%--- functions to extract what we need from results ---

% Data is a dictionary, the result returneed from the API
get_results(Data,R) :-
D = Data.get(data),
extract_flights(D,R).

%R is a resulting flight of res_flight([list of connecting flights], price)
%price is price(amount,currency) eg. price("500","EUR")
extract_flights([],_).
extract_flights([H|T], [R | List]) :-
Itineraries = H.get(itineraries),
Price = H.get(price),
parse_one(Itineraries,Price,R),
extract_flights(T, List).

%parse one of the returned flights (it can be a flight with a connecting flight), along with the
%price as res_flight([list of connecting flights], price)
%itineraries is a list passed in as the first element,
%but as we are only doing one way flights, it should only have one element, round trip has more
parse_one([],_,_).
parse_one([H|_],P,R) :-
R = res_flight(Flist,price(Price,C)),
Price = P.get(grandTotal),
C = P.get(currency),
S = H.get(segments),
parse_segment(S,Flist).

%a segment is one section of the whole trip. For example, it can be one connecting flight
parse_segment([],[]).
parse_segment([H|T] , [F|Flist]) :-
D = H.get(departure),
D_at = D.get(at),
D_code = D.get(iataCode),
A = H.get(arrival),
A_at = A.get(at),
A_code = A.get(iataCode),
C = H.get(carrierCode),
F = one_flight(D_at,D_code,A_at,A_code,C),
parse_segment(T,Flist).

%------- parse hotel results ----
%get the results from the api and parse them
get_hotel_results(Data,R) :-
    D = Data.get(data),
    parse_hotels(D,R).

%find the relevant information from the JSON dictionary
parse_hotels([],[]).
parse_hotels([H|T], [hotel(name(Name),desc(D_text)) | List]) :-
    Hotel = H.get(hotel),
    Description = Hotel.get(description),
    D_text = Description.get(text),
    Name = Hotel.get(name),
    parse_hotels(T,List),
    !.
parse_hotels([H|T], [hotel(name(Name),desc("none")) | List]) :-
    Hotel = H.get(hotel),
    Name = Hotel.get(name),
    parse_hotels(T,List).


%------ functions to produce readable output -------

%parses a list of res_flights
parse_list_flights([]).
parse_list_flights([H|T]):-
nl,
nl,
parse_flights(H,Result),
write("A flight option with associated connections and overall price is listed below:"), flush_output(current_output),
write(Result),
nl,
nl,
parse_list_flights(T).

% parses one res_flight
parse_flights(res_flight([H|T],price(A1,C1)),Answer):-
parse_list_one_flight([H|T],Flights),
parse_price(A1,C1,Price),
%string_concat(Price,"  ", A1),
append([Price],Flights, Answer).

% Parses a list of individual flights
parse_list_one_flight([],[]).
parse_list_one_flight([H|T],[Result|Answer]):-
parse_one_flight(H,Result),
parse_list_one_flight(T,Answer).

% parses one individual flight
parse_one_flight(one_flight(D1,D2,A1,A2,Air),Result):-
    string(D1),
    string(D2),
    string(A1),
    string(A2),
    string(Air),
    string_concat("Departure date and time is: ",D1,Dtim),
    string_concat("Departure Airport is: ",D2,Dplac),
    string_concat("Arrival date and time is: ",A1,Atim),
    string_concat("Arrival Airport is: ",A2,Aplac),
    string_concat("Airline is: ",Air,Airlin),
    string_concat(Dtim,", ", D3),
    string_concat(Dplac, ", ", D4),
    string_concat(Atim, ", ", A3),
    string_concat(Aplac, ", ", A4),
    string_concat(Airlin, " ' ", A5),
    string_concat(" 'Connection Description: ", D3, R1),
    string_concat(R1,D4, R3),
    string_concat(R3,A3,R4),
    string_concat(R4,A4,R5),
    string_concat(R5,A5,Result).

% Parses price only
parse_price(A1,C1,Price):-
    string_concat("Price is: ", A1, Amount),
    string_concat("Currency used is: ", C1, Currency),
    string_concat(Amount, ", ", A2),
    string_concat(A2,Currency,Price).

one_flight(_,_,_,_,_).
price(_,_).
res_flight([_],price(_,_)).

%print the resultts from the hotel calls in a nice readable form
print_hotels([]).
print_hotels([hotel(name(Name),desc(Desc)) |T]):-
nl,
write("hotel:"),
write(Name),
nl,
write(Desc),
nl,
nl,
print_hotels(T).
