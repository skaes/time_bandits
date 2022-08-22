# Time Bandits

## About

Time Bandits is a gem plugin for Rails which enhances Rails' controller/view/db benchmark logging.

![Build](https://github.com/skaes/time_bandits/actions/workflows/run-tests.yml/badge.svg)


## Usage

Without configuration, the standard Rails 'Completed line' will change
from its default format

    Completed 200 OK in 56ms (Views: 28.5ms, ActiveRecord: 5.1ms)

to:

    Completed 200 OK in 56.278ms (Views: 28.488ms, ActiveRecord: 5.111ms(2q,0h))

"ActiveRecord: 5.111ms(2q,0h)" means that 2 SQL queries were executed and there were 0 SQL query cache hits.

However, non-trivial applications also rather often use external services, which consume time that adds
to your total response time, and sometimes these external services are not under your control. In these
cases, it's very helpful to have an entry in your log file that records the time spent in the exterrnal
service (so that you can prove that it wasn't your rails app that slowed down during your slashdotting,
for example ;-).

Additional TimeConsumers can be added to the log using the "Timebandits.add" method.

Example:

    TimeBandits.add TimeBandits::TimeConsumers::Memcached
    TimeBandits.add TimeBandits::TimeConsumers::GarbageCollection.instance if GC.respond_to? :enable_stats

Here we've added two additional consumers, which are already provided with the
plugin. (Note that GC information requires a patched ruby, see prerequistes below.)

Note: if you run a multithreaded program, the numbers reported for garbage collections and
heap usage are partially misleading, because the Ruby interpreter collects stats in global
variables shared by all threads.

With these two new time consumers, the log line changes to

    Completed 200 OK in 680.378ms (Views: 28.488ms, ActiveRecord: 5.111ms(2q,0h), MC: 5.382(6r,0m), GC: 120.100(1), HP: 0(2000000,546468,18682541,934967))

"MC: 5.382(6r,0m)" means that 6 memcache reads were performed and all keys were found in the cache (0 misses).

"GC: 120.100(1)" tells us that 1 garbage collection was triggered during the request, taking 120.100 milliseconds.

"HP: 0(2000000,546468,18682541,934967)" shows statistics on heap usage. The format is g(s,a,b,l), where

   g: heap growth during the request (#slots)
   s: size of the heap after request processing was completed (#slots)
   a: number of object allocations during the request (#slots)
   b: number of bytes allocated by the ruby x_malloc call (#bytes)
   l: live data set size after last GC (#slots)

Side note for speakers of German: you can use the word "Gesabbel" (eng: drivel) as a mnemonic here ;-)

It's relatively straightforward to write additional time consumers; the more difficult part of this is
monkey patching the code which you want to instrument. Have a look at consumers under
`lib/time_bandits/time_consumers` and the corresponding patches under `lib/time_bandits/monkey_patches`.


## Prerequisites

ActiveSupport/Rails >= 5.2 is required. The gem will raise an error if you try to use it with an incompatible
version.

You'll need a ruby with the railsexpress GC patches applied, if you want to include GC and heap size
information in the completed line. This is very useful, especially if you want to analyze your rails
logs using logjam (see http://github.com/skaes/logjam/).

Ruby only contains a subset of the railsexpress patches. To get the full monty, you can use for example
rvm and the railsexpress rvm patchsets (see https://github.com/skaes/rvm-patchsets).


## History

This plugin started from the code of the 'custom_benchmark' plugin written by tylerkovacs. However, we
changed so much of the code that is is practically a full rewrite, hence we changed the name.

## Running Tests

Run `docker-compose up` to start Redis, MySQL, RabbitMQ and Memached containers, then run `rake`.
