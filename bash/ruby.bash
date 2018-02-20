export RAILS_ENV='development'
export RUBY_GC_HEAP_INIT_SLOTS=500000
export RUBY_HEAP_SLOTS_INCREMENT=250000
export RUBY_HEAP_SLOTS_GROWTH_FACTOR=1
export RUBY_GC_MALLOC_LIMIT=50000000
export RUBY_HEAP_FREE_MIN=4096


## rvm
sourceif "$BREWDIR/rvm/scripts/rvm"

alias brake='bundle exec rake'
