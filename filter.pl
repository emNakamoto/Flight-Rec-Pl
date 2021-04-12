:- module(filter, [compare_multiple_res_price/2,earliest_res_flight/2]).

%extracts the price of one res_flight and returns that res_flight
extract_one_res_flight_price(res_flight(_,price(Amount,_)), Answer):-
    string(Amount),
    number_string(Answer,Amount).

% takes list of res_flights, produces list of prices and list of associated Resflights.
list_prices([],[],[]).
list_prices([H|T],[Result|Rest],[H|Other]):-
    extract_one_res_flight_price(H,Result),
    list_prices(T,Rest,Other).

%Takes list of res_flights, finds the cheapest.
compare_multiple_res_price(List,Cheapest):-
    list_prices(List,Prices,Resflights),
    find_min(Prices,Resflights,Cheapest).

%Finds minimum price from list of prices but returns the associated res_flight.
find_min([_],Y,Y).

find_min([H,T1|T2],[RH,_|R2],Y) :-
    number(H),
    number(T1),
    H =< T1,                             
    find_min([H|T2],[RH|R2],Y).              

find_min([H,T1|T2],[_,R1|R2],Y) :-
    number(H),
    number(T1),
    H > T1,                             
    find_min([T1|T2],[R1|R2],Y).              


%test for cheapest price
%compare_multiple_res_price([res_flight([one_flight("2021-11-01T11:35:00", "SYD", "2021-11-01T16:50:00", "MNL", "PR"), one_flight("2021-11-01T19:20:00", "MNL", "2021-11-01T21:50:00", "BKK", "PR")|_7620], price("351.03", "EUR")), res_flight([one_flight("2021-11-01T11:35:00", "SYD", "2021-11-01T16:50:00", "MNL", "PR")|_7704], price("351.03", "EUR"))|_7666],Cheapest).

%Extracts the date and time for one_flight

extract_one_flight_date(one_flight(D1,_,_,_,_),Month,Day,Hours,Minutes):-
    string(D1),
    split_string(D1,"T","",[Date,Time]),
    string(Date),
    string(Time),
    split_string(Date,"-","",[_,M,D]),
    split_string(Time,":","",[H,Min,_]),
    number_string(Month,M),
    number_string(Day,D),
    number_string(Hours,H),
    number_string(Minutes,Min).

extract_one_res_flight_date(res_flight([H|_],_),Month,Day,Hours,Minutes):-
    extract_one_flight_date(H,Month,Day,Hours,Minutes).

%Creates list of months,days,hours, and minutes
list_date_times([],[],[],[],[],[]).
list_date_times([H|T],[M1|Months],[D1|Days],[H1|Hours],[M2|Minutes],[H|Other]):-
    extract_one_res_flight_date(H,M1,D1,H1,M2),
    list_date_times(T,Months,Days,Hours,Minutes,Other).

%takes multiple res flights, finds earliest
earliest_res_flight(List,E1):-
    list_date_times(List,Months,Days,Hours,Minutes,Resflights),
    find_earliest_date(Months,Days,Resflights,E1),
    find_earliest_time(Hours,Minutes,Resflights,E2),
    dif(E1,E2).

earliest_res_flight(List,E2):-
    list_date_times(List,Months,Days,Hours,Minutes,Resflights),
    find_earliest_date(Months,Days,Resflights,_),
    find_earliest_time(Hours,Minutes,Resflights,E2).
   

%If finding the min of month and min of day results in 2 different answers, the
% answer must be the min of months because it indicates the months are different
find_earliest_date(Months,Days,Resflights,E1):-
    find_min(Months,Resflights,E1),
    find_min(Days,Resflights,E2),
    dif(E1,E2).

%If finding the min of month and min of day results in the same answer, suggests
% the months are the same, but the days are different.
find_earliest_date(Months,Days,Resflights,E2):-
    find_min(Months,Resflights,_),
    find_min(Days,Resflights,E2).

%If finding the min of hours and min of minutes results in 2 different answers, the
% answer must be the min of hours because it indicates the hours are different
find_earliest_time(Hours,Minutes,Resflights,E1):-
    find_min(Hours,Resflights,E1),
    find_min(Minutes,Resflights,E2),
    dif(E1,E2).

%If finding the min of hours and min of minutes results in the same answer, suggests
% the hours are the same, but the minutes are different.
find_earliest_time(Hours,Minutes,Resflights,E2):-
    find_min(Hours,Resflights,_),
    find_min(Minutes,Resflights,E2).


%Date test case:

%earliest_res_flight([res_flight([one_flight("2021-11-01T11:35:00", "SYD", "2021-11-01T16:50:00", "MNL", "PR"), one_flight("2021-11-01T19:20:00", "MNL", "2021-11-01T21:50:00", "BKK", "PR")|_7620], price("351.03", "EUR")), res_flight([one_flight("2021-11-01T11:35:00", "SYD", "2021-11-01T16:50:00", "MNL", "PR")|_7704], price("351.03", "EUR"))|_7666],Earliest).

