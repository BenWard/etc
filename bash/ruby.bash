export SBT_TWITTER=1

export RAILS_ENV='development'
export RUBY_HEAP_MIN_SLOTS=250000
export RUBY_HEAP_SLOTS_INCREMENT=250000
export RUBY_HEAP_SLOTS_GROWTH_FACTOR=1
export RUBY_GC_MALLOC_LIMIT=50000000

export rvm_path=/usr/local/rvm
if [[ -s $rvm_path/scripts/rvm ]] ; then source $rvm_path/scripts/rvm ; fi

alias brake='bundle exec rake'