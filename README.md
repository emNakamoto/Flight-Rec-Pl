# Flight-Rec-Pl
a flight recommender
Ask the recommender about flights between two airports and see what routes it recommends taking.
We are using the Amadeus for Developers API to make calls.

Some restrictions from the API:
1. You can't try and find flights that happened in the past.
2. There are limits to how far ahead the API can check. I believe it is 6 months.
3. The API will give the cheapest flights under a max price

Some questions you can ask.
What is the cheapest flight from YVR to NRT in September?
Is there a flight between 100 and 3000 dollars from TPE to BKK on July 12, 2021?
What is a flight from HND to PAR in May?

Locations must be given in IATA codes in the format from A to B.
Dates must be given as just the month, or as Month Day, Year.
Also Because of restriction 3 from the API, you are welcome to ask the recommender for a flight above a certain price (you can specify a minimum), but if it finds a cheaper flight it will give you that instead. It worries about your wallet :) 


