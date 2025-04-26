Thingerthing to temporarily disable blocking on pihole. This will only work with newer pihole version (v6 I think). The required REST api didn't exist previously.

set api base to `PIHOLE_BASE_URL` environment variable. For example if your pihole's url is https://pi.hole then this should be set to https://pi.hole/api. This behavior will likely change.

set your pihole password to `PIHOLE_PASS` environment variable.

To configure how long to disable set environment variable `PIHOLE_TIMER_SEC` to a numeric value from 0 to 300. The default is 120 (2 minutes).

Why are these all environment variables and no overriding flags/args? For my usecase run by run flexibility is neither required nor, in it's current form, desirable. I opted to solve this in a way that doesn't require a separate file.

Why Pony?
I enjoyed using it for advent of code a few years back but not yet in a real usecase and needed a Windows executable with no dependencies. This choice ended up being...interesting. Pony's Reference Capabilities aren't something that lends itself well to year+ breaks after brief usage 😂. I stuck to the example implementation of the http package pretty closely. Implementing multiple requests from this as a starting point without any actor/class/trait relationship changes ended up being a bit verbose and I kludged the response handler but good. In the end this paragraph took more time to write and likely used more characters than something like a node solution would have. Wait what?
