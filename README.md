Thingerthing to temporarily disable blocking on pihole. This will only work with newer pihole version (v6 I think). The required REST api didn't exist previously.

set api base to PIHOLE_BASE_URL environment variable. For example if your pihole's url is https://pi.hole then this should be set to https://pi.hole/api. this'll probably change

set your pihole password to PIHOLE_PASS environment variable.

someday will add a timer env variable probably, is a tiny change but I'm going to bed. currently hardcoded 2min.
