:- module(api_call, [get_api_results/2,get_api_hotel/2]).
:- use_module(library(http/http_client)).
:- use_module(library(http/json)).
:- use_module(library(http/http_open)).


%https://www.iata.org/en/publications/directories/code-search/

flight_offer_url("https://test.api.amadeus.com/v2/shopping/flight-offers?currencyCode=CAD&adults=1&max=5").

hotel_url("https://test.api.amadeus.com/v2/shopping/hotel-offers?cityCode=").

%token valid for 30 minutes
token('X').

%dall the api
make_api_call(URL,Data) :-
token(T),
setup_call_cleanup(
http_open(URL, In, [request_header('Accept'='application/json'),authorization(bearer(T))]),
json_read_dict(In, Data),
close(In)
).

% ------- function to build query ---
%parse through our constraints to figure out the API url
parse_query_offers_params([], []).
parse_query_offers_params([price_range(_,Max)|T], [Param|P]) :-
    dif(Max,any),
    parse_offers_param(maxPrice(Max), Param),
    parse_query_offers_params(T, P).
parse_query_offers_params([price_range(Min,any)|T], [Param|P]) :-
    Max is Min+1000,
    parse_offers_param(maxPrice(Max), Param),
    parse_query_offers_params(T, P).
parse_query_offers_params([destination(Src, Dst)|T], [P1,P2|P]) :-
    parse_offers_param(source(Src), P1),
    parse_offers_param(dest(Dst), P2),
    parse_query_offers_params(T, P).
parse_query_offers_params([time_range(Start,any)|T], [Param|P]) :-
    parse_offers_param(date(Start), Param),
    parse_query_offers_params(T, P).
parse_query_offers_params([time_range(any,Date)|T], [Param|P]) :-
    parse_offers_param(date(Date), Param),
    parse_query_offers_params(T, P).
parse_query_offers_params([time_range(D1,D2)|T], [Param|P]) :-
    dif(D1,any),
    dif(D2,any),
    parse_offers_param(date(D1), Param),
    parse_query_offers_params(T, P).


% Bi-directional conversion from predicate constraint to key-value pair
parse_offers_param(dest(Destination), keyPair('destinationLocationCode', Destination)).
parse_offers_param(source(Src), keyPair('originLocationCode', Src)).
parse_offers_param(maxPrice(Price), keyPair('maxPrice', Price)).
parse_offers_param(date(D), keyPair('departureDate', D)).

%create the url from the constraints and call the api
get_api_results(Constraints, Data) :-
    make_url(Constraints,URL),
    make_api_call(URL, Data).

%create the url from the constraints
make_url(Constraints, URL) :-
    flight_offer_url(U),
    parse_query_offers_params(Constraints, Params),
    add_query_params(U, Params, URL).


% Adds query parameters to given url.
add_query_params(Url, [], Url).
add_query_params(Url, [keyPair(Key, Val)|Tail], NewUrl) :-
    make_query_param(Key, Val, Param),
    string_concat(Url, Param, NextUrl),
    add_query_params(NextUrl, Tail, NewUrl).


% Transforms key, val => "&" + Key + "=" + Val
make_query_param(Key, Val, Param) :-
    string_concat("&", Key, Front),
    string_concat("=", Val, Back),
    string_concat(Front, Back, Param).

%make the url to get nearby hotels and call the api
get_api_hotel(Dst,Data) :-
    hotel_url(X),
    string_concat(X,Dst,URL),
    make_api_call(URL,Data).
